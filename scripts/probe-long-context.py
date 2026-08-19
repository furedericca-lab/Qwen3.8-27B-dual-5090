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
parser.add_argument('--target-tokens', type=int, default=32768, help='Server context to exercise. Must be between 32768 and 262144 inclusive.')
parser.add_argument('--headroom-tokens', type=int, default=1024, help='Reserved chat framing and generation capacity.')
args = parser.parse_args()
if args.target_tokens < 32768 or args.target_tokens > 262144:
    raise SystemExit('--target-tokens must be between 32768 and 262144')
if args.headroom_tokens < 256 or args.headroom_tokens >= args.target_tokens:
    raise SystemExit('--headroom-tokens must be at least 256 and below --target-tokens')

prompt_target = args.target_tokens - args.headroom_tokens

root = pathlib.Path(__file__).resolve().parents[1]
run_dir = root / 'evidence' / f'long-context-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}'
run_dir.mkdir(parents=True)
needle = 'NEEDLE: the verified deployment color is cobalt-73.'
filler = 'Document segment confirms independent context handling and deterministic retrieval. '
filler_tokens = max(1, token_count(args.base_url, filler))
copies = max(1, prompt_target // filler_tokens)
prompt = filler * copies
current = token_count(args.base_url, prompt)
while current < prompt_target:
    missing = prompt_target - current
    prompt += filler * max(1, missing // filler_tokens)
    current = token_count(args.base_url, prompt)
prompt += needle
payload = {'model': 'default', 'messages': [{'role': 'user', 'content': prompt + '\nWhat is the verified deployment color? Reply with only the color.'}], 'temperature': 0, 'max_tokens': 256, 'chat_template_kwargs': {'enable_thinking': False}}
result = request(args.base_url + '/v1/chat/completions', payload)
(run_dir / 'response.json').write_text(json.dumps(result, indent=2) + '\n')
usage = result.get('usage', {})
content = result['choices'][0]['message'].get('content') or ''
if usage.get('prompt_tokens', 0) < prompt_target:
    raise SystemExit(f'FAIL: prompt used {usage.get("prompt_tokens", 0)} tokens, below target {prompt_target}')
if 'cobalt-73' not in content.lower():
    raise SystemExit('FAIL: needle retrieval failed')
(run_dir / 'summary.json').write_text(json.dumps({
    'server_context_tokens': args.target_tokens,
    'reserved_headroom_tokens': args.headroom_tokens,
    'prompt_target_tokens': prompt_target,
    'actual_prompt_tokens': usage['prompt_tokens'],
}) + '\n')
print(f'PASS: context={args.target_tokens} prompt={usage["prompt_tokens"]} headroom={args.headroom_tokens} retained in {run_dir}')
