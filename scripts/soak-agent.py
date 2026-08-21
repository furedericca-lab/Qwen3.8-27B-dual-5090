#!/usr/bin/env python3
"""Run a deterministic local tool-call continuation soak against llama-server."""

import argparse
import json
import pathlib
import time

from responses_api import output_items, request, require_completed


parser = argparse.ArgumentParser()
parser.add_argument('--base-url', default='http://172.30.0.214:8000')
parser.add_argument('--turns', type=int, choices=range(20, 51), default=20)
parser.add_argument('--run-dir')
args = parser.parse_args()

root = pathlib.Path(__file__).resolve().parents[1]
run_dir = pathlib.Path(args.run_dir) if args.run_dir else root / 'evidence' / f'agent-soak-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}'
run_dir.mkdir(parents=True, exist_ok=bool(args.run_dir))
input_items = [{'role': 'user', 'content': 'Use lookup once per turn. Start with turn 1.'}]
tool = {'type': 'function', 'name': 'lookup', 'description': 'Return a deterministic record.', 'parameters': {'type': 'object', 'properties': {'turn': {'type': 'integer'}}, 'required': ['turn']}}
history = []

for expected_turn in range(1, args.turns + 1):
    response = require_completed(request(args.base_url + '/v1/responses', {'model': 'default', 'input': input_items, 'tools': [tool], 'tool_choice': 'required', 'parallel_tool_calls': False, 'temperature': 0, 'max_output_tokens': 128, 'stream': False, 'chat_template_kwargs': {'enable_thinking': False}}), f'tool turn {expected_turn}')
    (run_dir / f'turn-{expected_turn:02d}.json').write_text(json.dumps(response, indent=2) + '\n')
    calls = output_items(response, 'function_call')
    if len(calls) != 1 or calls[0].get('name') != 'lookup':
        raise SystemExit(f'FAIL: turn {expected_turn} did not produce exactly one lookup call')
    call = calls[0]
    arguments = json.loads(call['arguments'])
    if arguments.get('turn') != expected_turn:
        raise SystemExit(f'FAIL: turn {expected_turn} arguments were {arguments!r}')
    input_items.append({'type': 'function_call', 'call_id': call['call_id'], 'name': call['name'], 'arguments': call['arguments']})
    input_items.append({'type': 'function_call_output', 'call_id': call['call_id'], 'output': json.dumps({'turn': expected_turn, 'status': 'ok'})})
    input_items.append({'role': 'user', 'content': f'Continue with lookup turn {expected_turn + 1}.'})
    history.append(response)

(run_dir / 'responses.json').write_text(json.dumps(history, indent=2) + '\n')
print(f'PASS: {args.turns} deterministic tool-call turns retained in {run_dir}')
