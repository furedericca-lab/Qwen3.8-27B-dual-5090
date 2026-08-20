#!/usr/bin/env python3
"""Benchmark speculative MTP decoding on the already-running canonical server."""

import argparse
import atexit
import json
import pathlib
import re
import subprocess
import time

from responses_api import request, request_text, require_completed


def metrics(base_url):
    return request_text(base_url + '/metrics')


def metric_value(body, name):
    match = re.search(rf'^{re.escape(name)}\s+([0-9]+(?:\.[0-9]+)?)$', body, re.MULTILINE)
    return float(match.group(1)) if match else 0.0


parser = argparse.ArgumentParser()
parser.add_argument('--base-url', default='http://127.0.0.1:8000')
parser.add_argument('--runs', type=int, default=3)
parser.add_argument('--run-dir')
args = parser.parse_args()
if args.runs < 2:
    raise SystemExit('--runs must be at least 2 so one warm-up can be excluded')

root = pathlib.Path(__file__).resolve().parents[1]
run_dir = pathlib.Path(args.run_dir) if args.run_dir else root / 'evidence' / f'mtp-server-benchmark-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}'
run_dir.mkdir(parents=True, exist_ok=bool(args.run_dir))
(run_dir / 'gpu-before.csv').write_text(subprocess.check_output([
    'nvidia-smi', '--query-gpu=index,name,memory.used,memory.free,power.draw', '--format=csv,noheader'
], text=True))
(run_dir / 'memory-before.txt').write_text(subprocess.check_output(['free', '-h'], text=True))
(run_dir / 'swap-before.txt').write_text(subprocess.check_output(['swapon', '--show'], text=True))
gpu_samples = (run_dir / 'gpu-samples.csv').open('w')
sampler = subprocess.Popen([
    'nvidia-smi', '--query-gpu=index,name,memory.used,memory.free,power.draw', '--format=csv,noheader', '-l', '1'
], stdout=gpu_samples)


def stop_sampler():
    if sampler.poll() is None:
        sampler.terminate()
        sampler.wait(timeout=10)
    gpu_samples.close()


atexit.register(stop_sampler)
(run_dir / 'metrics-before.prom').write_text(metrics(args.base_url))

workloads = {'short': 256, 'medium': 1024, 'long': 4096}
summary = []
for name, max_tokens in workloads.items():
    samples = []
    for number in range(1, args.runs + 1):
        payload = {
            'model': 'default',
            'input': 'Write a precise technical explanation of deterministic software validation.',
            'temperature': 0,
            'max_output_tokens': max_tokens,
            'stream': False,
            'chat_template_kwargs': {'enable_thinking': False},
        }
        started = time.monotonic()
        response = require_completed(
            request(args.base_url + '/v1/responses', payload),
            f'{name} run {number}',
        )
        elapsed = time.monotonic() - started
        usage = response.get('usage', {})
        tokens = usage.get('output_tokens', 0)
        if tokens <= 0:
            raise SystemExit(f'FAIL: {name} run {number} returned no completion tokens')
        sample = {
            'run': number,
            'output_tokens': tokens,
            'elapsed_seconds': elapsed,
            'output_tokens_per_second': tokens / elapsed,
            'response': response,
        }
        samples.append(sample)
        (run_dir / f'{name}-{number}.json').write_text(json.dumps(sample, indent=2) + '\n')
    measured = samples[1:]
    summary.append({
        'workload': name,
        'requested_max_tokens': max_tokens,
        'measured_runs': len(measured),
        'mean_output_tokens_per_second': sum(s['output_tokens_per_second'] for s in measured) / len(measured),
        'samples': [{key: value for key, value in s.items() if key != 'response'} for s in samples],
    })

after = metrics(args.base_url)
(run_dir / 'metrics-after.prom').write_text(after)
stop_sampler()
(run_dir / 'gpu-after.csv').write_text(subprocess.check_output([
    'nvidia-smi', '--query-gpu=index,name,memory.used,memory.free,power.draw', '--format=csv,noheader'
], text=True))
(run_dir / 'memory-after.txt').write_text(subprocess.check_output(['free', '-h'], text=True))
(run_dir / 'swap-after.txt').write_text(subprocess.check_output(['swapon', '--show'], text=True))
drafted_name = 'llamacpp:spec_decode_num_draft_tokens_total'
accepted_name = 'llamacpp:spec_decode_num_accepted_tokens_total'
drafted = metric_value(after, drafted_name) - metric_value((run_dir / 'metrics-before.prom').read_text(), drafted_name)
accepted = metric_value(after, accepted_name) - metric_value((run_dir / 'metrics-before.prom').read_text(), accepted_name)
if drafted <= 0 or accepted <= 0:
    raise SystemExit(f'FAIL: MTP metrics did not advance: drafted={drafted:g} accepted={accepted:g}')

result = {
    'workloads': summary,
    'mtp_drafted_tokens': drafted,
    'mtp_accepted_tokens': accepted,
    'mtp_acceptance_rate': accepted / drafted,
}
(run_dir / 'summary.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
print(f'PASS: MTP server benchmark retained in {run_dir}')
