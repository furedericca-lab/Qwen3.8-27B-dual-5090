#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
base_url=${BASE_URL:-http://127.0.0.1:8000}
run_dir="$root/evidence/probe-basic-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$run_dir"

curl -fsS "$base_url/health" | tee "$run_dir/health.json"
curl -fsS "$base_url/v1/models" | tee "$run_dir/models.json"

probe() {
  local name=$1 prompt=$2
  jq -n --arg prompt "$prompt" '{model:"default",messages:[{role:"user",content:$prompt}],temperature:0,max_tokens:256,chat_template_kwargs:{enable_thinking:false}}' \
    | curl -fsS "$base_url/v1/chat/completions" -H 'Content-Type: application/json' -d @- \
    | tee "$run_dir/$name.json"
}

probe chinese '请用中文解释为什么单元测试应该保持确定性。'
probe json 'Only return JSON: {"sum": 2, "language": "Python"}.'
probe python 'Write a Python function add(a, b) that returns their sum.'

python3 - "$run_dir" <<'PY'
import json
import pathlib
import sys

run_dir = pathlib.Path(sys.argv[1])
for path in sorted(run_dir.glob('*.json')):
    if path.name in {'health.json', 'models.json'}:
        continue
    body = json.loads(path.read_text())
    content = body['choices'][0]['message'].get('content') or ''
    if not content.strip() or '<|' in content or '!!!!!!' in content:
        raise SystemExit(f'FAIL: anomalous response in {path.name}')
print(f'PASS: basic responses retained in {run_dir}')
PY
