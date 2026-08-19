#!/usr/bin/env python3
"""Run a deterministic local tool-call continuation soak against llama-server."""

import argparse
import json
import pathlib
import time
import urllib.request


def request(url, payload):
    body = json.dumps(payload).encode()
    req = urllib.request.Request(url, body, {'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=600) as response:
        return json.loads(response.read())


parser = argparse.ArgumentParser()
parser.add_argument('--base-url', default='http://127.0.0.1:8000')
parser.add_argument('--turns', type=int, choices=range(20, 51), default=20)
args = parser.parse_args()

root = pathlib.Path(__file__).resolve().parents[1]
run_dir = root / 'evidence' / f'agent-soak-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}'
run_dir.mkdir(parents=True)
messages = [{'role': 'user', 'content': 'Use lookup once per turn. Start with turn 1.'}]
tool = {'type': 'function', 'function': {'name': 'lookup', 'description': 'Return a deterministic record.', 'parameters': {'type': 'object', 'properties': {'turn': {'type': 'integer'}}, 'required': ['turn']}}}
history = []

for expected_turn in range(1, args.turns + 1):
    response = request(args.base_url + '/v1/chat/completions', {'model': 'default', 'messages': messages, 'tools': [tool], 'tool_choice': 'required', 'parallel_tool_calls': False, 'temperature': 0, 'max_tokens': 128, 'chat_template_kwargs': {'enable_thinking': False}})
    (run_dir / f'turn-{expected_turn:02d}.json').write_text(json.dumps(response, indent=2) + '\n')
    message = response['choices'][0]['message']
    calls = message.get('tool_calls') or []
    if len(calls) != 1 or calls[0].get('function', {}).get('name') != 'lookup':
        raise SystemExit(f'FAIL: turn {expected_turn} did not produce exactly one lookup call')
    arguments = json.loads(calls[0]['function']['arguments'])
    if arguments.get('turn') != expected_turn:
        raise SystemExit(f'FAIL: turn {expected_turn} arguments were {arguments!r}')
    messages.append(message)
    messages.append({'role': 'tool', 'tool_call_id': calls[0]['id'], 'content': json.dumps({'turn': expected_turn, 'status': 'ok'})})
    messages.append({'role': 'user', 'content': f'Continue with lookup turn {expected_turn + 1}.'})
    history.append(response)

(run_dir / 'responses.json').write_text(json.dumps(history, indent=2) + '\n')
print(f'PASS: {args.turns} deterministic tool-call turns retained in {run_dir}')
