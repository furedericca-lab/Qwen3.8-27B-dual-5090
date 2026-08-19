#!/usr/bin/env python3
"""Measure one long-prompt prefill request against a running llama-server."""

import argparse
import json
import pathlib
import subprocess
import threading
import time
import urllib.request


def request(url, payload):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data, {"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=1800) as response:
        return json.loads(response.read())


def gpu_sampler(path, stop):
    with path.open("w") as output:
        output.write("unix_time,gpu_index,memory_used_mib,memory_free_mib\n")
        while not stop.is_set():
            rows = subprocess.check_output(
                ["nvidia-smi", "--query-gpu=index,memory.used,memory.free", "--format=csv,noheader,nounits"],
                text=True,
            )
            now = time.time()
            for row in rows.splitlines():
                output.write(f"{now:.3f},{row.replace(' ', '')}\n")
            output.flush()
            stop.wait(0.2)


parser = argparse.ArgumentParser()
parser.add_argument("--base-url", required=True)
parser.add_argument("--target-tokens", type=int, required=True)
parser.add_argument("--run-dir", type=pathlib.Path, required=True)
args = parser.parse_args()
args.run_dir.mkdir(parents=True, exist_ok=True)

filler = "Document segment confirms deterministic context processing and repeatable validation. "
filler_tokens = len(request(args.base_url + "/tokenize", {"content": filler})["tokens"])
prompt = filler * max(1, args.target_tokens // filler_tokens)
current = len(request(args.base_url + "/tokenize", {"content": prompt})["tokens"])
while current < args.target_tokens:
    prompt += filler
    current = len(request(args.base_url + "/tokenize", {"content": prompt})["tokens"])

payload = {
    "model": "default",
    "messages": [{"role": "user", "content": prompt}],
    "temperature": 0,
    "max_tokens": 1,
    "cache_prompt": False,
    "chat_template_kwargs": {"enable_thinking": False},
}
(args.run_dir / "request.json").write_text(
    json.dumps({**payload, "messages": [{"role": "user", "content": f"<prompt with {current} raw tokens>"}]}, indent=2) + "\n"
)

stop = threading.Event()
sampler = threading.Thread(target=gpu_sampler, args=(args.run_dir / "gpu-samples.csv", stop))
sampler.start()
started = time.monotonic()
try:
    response = request(args.base_url + "/v1/chat/completions", payload)
finally:
    elapsed = time.monotonic() - started
    stop.set()
    sampler.join()

(args.run_dir / "response.json").write_text(json.dumps(response, indent=2) + "\n")
usage = response.get("usage", {})
timings = response.get("timings", {})
finish_reason = response.get("choices", [{}])[0].get("finish_reason")
if usage.get("prompt_tokens", 0) < args.target_tokens:
    raise SystemExit(f"FAIL: prompt_tokens={usage.get('prompt_tokens', 0)} target={args.target_tokens}")
if usage.get("completion_tokens", 0) < 1 or not finish_reason:
    raise SystemExit("FAIL: response did not contain a completed generation")

peaks = {}
for line in (args.run_dir / "gpu-samples.csv").read_text().splitlines()[1:]:
    _, index, used, _ = line.split(",")
    peaks[index] = max(peaks.get(index, 0), int(used))

summary = {
    "target_prompt_tokens": args.target_tokens,
    "actual_prompt_tokens": usage["prompt_tokens"],
    "prompt_tokens_per_second": timings.get("prompt_per_second"),
    "server_prompt_ms": timings.get("prompt_ms"),
    "ttft_wall_ms": elapsed * 1000,
    "completion_tokens": usage["completion_tokens"],
    "finish_reason": finish_reason,
    "peak_gpu0_mib": peaks.get("0"),
    "peak_gpu1_mib": peaks.get("1"),
}
(args.run_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary))
