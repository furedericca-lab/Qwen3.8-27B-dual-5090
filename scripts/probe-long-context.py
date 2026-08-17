#!/usr/bin/env python3
"""Exercise one measured long-context request against a running local server."""

import argparse
import json
import pathlib
import time
import urllib.request


def request(url, payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(url, body, {'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=1800) as response:
        return json.loads(response.read())


def token_count(base_url, content):
    return len(request(base_url + '/tokenize', {'content': content})['tokens'])


parser = argparse.ArgumentParser()
parser.add_argument('--base-url', default='http://127.0.0.1:8000')
parser.add_argument('--target-tokens', type=int, choices=(32768, 131072, 196608, 262144), default=32768)
args = parser.parse_args()

root = pathlib.Path(__file__).resolve().parents[1]
run_dir = root / 'evidence' / f'long-context-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}'
run_dir.mkdir(parents=True)
needle = 'NEEDLE: the verified deployment color is cobalt-73.'
filler = 'Document segment confirms independent context handling and deterministic retrieval. '
prompt = filler * ((args.target_tokens * 4) // len(filler))
while token_count(args.base_url, prompt) < args.target_tokens:
    prompt += prompt
prompt += needle
payload = {'model': 'default', 'messages': [{'role': 'user', 'content': prompt + '\nWhat is the verified deployment color? Reply with only the color.'}], 'temperature': 0, 'max_tokens': 256}
result = request(args.base_url + '/v1/chat/completions', payload)
(run_dir / 'response.json').write_text(json.dumps(result, indent=2) + '\n')
usage = result.get('usage', {})
content = result['choices'][0]['message'].get('content') or ''
if usage.get('prompt_tokens', 0) < args.target_tokens:
    raise SystemExit(f'FAIL: prompt used {usage.get("prompt_tokens", 0)} tokens, below target {args.target_tokens}')
if 'cobalt-73' not in content.lower():
    raise SystemExit('FAIL: needle retrieval failed')
print(f'PASS: {usage["prompt_tokens"]} prompt tokens retained in {run_dir}')
