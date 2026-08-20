#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
base_url=${BASE_URL:-http://172.30.0.214:8000}
run_dir="$root/evidence/probe-basic-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$run_dir"

curl -fsS "$base_url/health" | tee "$run_dir/health.json"
curl -fsS "$base_url/v1/models" | tee "$run_dir/models.json"

probe() {
  local name=$1 prompt=$2
  jq -n --arg prompt "$prompt" '{model:"default",input:$prompt,temperature:0,max_output_tokens:256,stream:false,chat_template_kwargs:{enable_thinking:false}}' \
    | curl -fsS "$base_url/v1/responses" -H 'Content-Type: application/json' -d @- \
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
    content = ''.join(
        part.get('text', '')
        for item in body.get('output', [])
        if item.get('type') == 'message'
        for part in item.get('content', [])
        if part.get('type') == 'output_text'
    )
    if body.get('status') != 'completed' or not content.strip() or '<|' in content or '!!!!!!' in content:
        raise SystemExit(f"FAIL: anomalous Responses API response in {path.name}: status={body.get('status')!r}")
print(f'PASS: basic responses retained in {run_dir}')
PY
