#!/usr/bin/env python3
"""Exercise one measured long-context request against a running local server."""

import argparse
import json
import pathlib
import time

from responses_api import output_text, request, require_completed


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
payload = {'model': 'default', 'input': prompt + '\nWhat is the verified deployment color? Reply with only the color.', 'temperature': 0, 'max_output_tokens': 256, 'stream': False, 'chat_template_kwargs': {'enable_thinking': False}}
result = require_completed(request(args.base_url + '/v1/responses', payload), 'long-context')
(run_dir / 'response.json').write_text(json.dumps(result, indent=2) + '\n')
usage = result.get('usage', {})
content = output_text(result)
if usage.get('input_tokens', 0) < prompt_target:
    raise SystemExit(f'FAIL: input used {usage.get("input_tokens", 0)} tokens, below target {prompt_target}')
if 'cobalt-73' not in content.lower():
    raise SystemExit('FAIL: needle retrieval failed')
(run_dir / 'summary.json').write_text(json.dumps({
    'server_context_tokens': args.target_tokens,
    'reserved_headroom_tokens': args.headroom_tokens,
    'prompt_target_tokens': prompt_target,
    'actual_input_tokens': usage['input_tokens'],
}) + '\n')
print(f'PASS: context={args.target_tokens} input={usage["input_tokens"]} headroom={args.headroom_tokens} retained in {run_dir}')
