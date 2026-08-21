#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
changed=${1:-}
value=${2:-}
profile=${PROFILE:-baseline}
port=${PORT:-8001}
base_url="http://127.0.0.1:$port"
template_mode=${TEMPLATE:-upstream}

[[ $changed == mmproj && $value == on ]] || {
  echo "usage: PROFILE=baseline PORT=8001 scripts/run-vision-candidate.sh mmproj on" >&2
  exit 2
}
[[ $template_mode == upstream || $template_mode == hf ]] || { echo "TEMPLATE must be upstream or hf" >&2; exit 1; }
if pgrep -f '^.*/llama-server( |$)' >/dev/null; then
  echo "FAIL: llama-server already running; stop the formal systemd server before a candidate run" >&2
  exit 1
fi

safe_template=${template_mode//[^[:alnum:]]/_}
run_dir=${RUN_DIR:-"$root/evidence/vision-candidate-mmproj-on-${safe_template}-$(date -u +%Y%m%dT%H%M%SZ)"}
mkdir -p "$run_dir"
{
  printf 'changed_variable=%s\n' "$changed"
  printf 'value=%s\n' "$value"
  printf 'profile=%s\n' "$profile"
  printf 'port=%s\n' "$port"
  printf 'template=%s\n' "$template_mode"
  printf 'fit_target=2048,2048\n'
  printf 'context=%s\n' "$([[ $profile == agent ]] && echo 262144 || echo 32768)"
  printf 'draft_n_max=3\n'
  printf 'model_sha256='
  awk 'NF && $1 !~ /^#/ {print $1; exit}' "$root/evidence/model.sha256"
  printf 'mmproj_sha256='
  sha256sum /data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/mmproj-Qwen3.8-27B-Q8_0.gguf | awk '{print $1}'
  printf 'llama_cpp_sha='
  git -C "$root/llama.cpp" rev-parse HEAD
} | tee "$run_dir/config.txt"

"$root/scripts/inspect-topology.sh" "$run_dir/topology" >"$run_dir/topology.log" 2>&1
"$root/scripts/preflight.sh" >"$run_dir/preflight-before.txt" 2>&1

PROFILE="$profile" PORT="$port" TEMPLATE="$template_mode" \
  "$root/scripts/candidate-server.sh" "$changed" "$value" >"$run_dir/server.log" 2>&1 &
server_pid=$!
cleanup() {
  if kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

ready=0
for _ in $(seq 1 180); do
  if curl -fsS "$base_url/health" >"$run_dir/health.json" 2>/dev/null; then
    ready=1
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    break
  fi
  sleep 2
done
if (( ! ready )); then
  echo "FAIL: candidate server did not become healthy" >&2
  tail -n 120 "$run_dir/server.log" >&2 || true
  exit 1
fi

curl -fsS "$base_url/v1/models" >"$run_dir/models.json"
curl -fsS "$base_url/metrics" >"$run_dir/metrics-before.prom"
nvidia-smi --query-gpu=index,name,driver_version,memory.total,memory.used,memory.free --format=csv,noheader >"$run_dir/gpu-startup.csv"
free -h >"$run_dir/memory-startup.txt"
swapon --show >"$run_dir/swap-startup.txt"

python3 - "$run_dir/models.json" >"$run_dir/models-check.txt" <<'PY'
import json
import pathlib
import sys

body = json.loads(pathlib.Path(sys.argv[1]).read_text())
models = body.get("models") or body.get("data", [])
if not models:
    raise SystemExit("FAIL: /v1/models returned no models")
model = models[0]
capabilities = model.get("capabilities")
print(f"model={model.get('id', model.get('name', 'unknown'))}")
print(f"capabilities={capabilities!r}")
if capabilities and "multimodal" in capabilities:
    print("multimodal_capability=PASS")
else:
    print("multimodal_capability=NOT_ADVERTISED")
PY

if rg -ni 'out of memory|failed to allocate|cuda error|nvrm.*xid|bad_page' "$run_dir/server.log"; then
  echo "FAIL: candidate startup log contains an allocation or host-integrity error" >&2
  exit 1
fi
{
  echo '=== multimodal and projector lines ==='
  rg -ni 'mmproj|multimodal|mtmd|vision' "$run_dir/server.log" || true
  echo '=== offload lines ==='
  rg -ni 'offload|kv.*cpu|cpu.*kv' "$run_dir/server.log" || true
} >"$run_dir/runtime-checks.txt"

RUN_DIR="$run_dir/text-before" BASE_URL="$base_url" "$root/scripts/probe-basic.sh" >"$run_dir/text-before.log" 2>&1
"$root/scripts/preflight.sh" >"$run_dir/preflight-before-vision.txt" 2>&1
python3 "$root/scripts/probe-vision.py" --base-url "$base_url" --sequence --run-dir "$run_dir/vision-sequence" >"$run_dir/vision-sequence.log" 2>&1
curl -fsS "$base_url/metrics" >"$run_dir/metrics-after.prom"
nvidia-smi --query-gpu=index,name,driver_version,memory.total,memory.used,memory.free --format=csv,noheader >"$run_dir/gpu-after.csv"
free -h >"$run_dir/memory-after.txt"
swapon --show >"$run_dir/swap-after.txt"

python3 - "$run_dir/metrics-before.prom" "$run_dir/metrics-after.prom" "$run_dir/config.txt" >"$run_dir/mtp-sequence-summary.json" <<'PY'
import json
import pathlib
import re
import sys

def metric(path, name):
    pattern = rf"^{re.escape(name)}\s+([0-9]+(?:\.[0-9]+)?)$"
    for line in pathlib.Path(path).read_text().splitlines():
        match = re.match(pattern, line)
        if match:
            return float(match.group(1))
    return 0.0

before, after, config = sys.argv[1:]
drafted_name = "llamacpp:spec_decode_num_draft_tokens_total"
accepted_name = "llamacpp:spec_decode_num_accepted_tokens_total"
drafted = metric(after, drafted_name) - metric(before, drafted_name)
accepted = metric(after, accepted_name) - metric(before, accepted_name)
result = {
    "draft_n_max": 3,
    "sequence": "text -> image -> text",
    "drafted_tokens_delta": drafted,
    "accepted_tokens_delta": accepted,
    "acceptance_rate": accepted / drafted if drafted else 0,
    "config_path": config,
}
print(json.dumps(result, indent=2))
if drafted <= 0 or accepted <= 0:
    raise SystemExit(f"FAIL: MTP metrics did not advance after vision sequence: drafted={drafted:g} accepted={accepted:g}")
PY

cleanup
trap - EXIT
"$root/scripts/preflight.sh" >"$run_dir/preflight-after.txt" 2>&1
echo "PASS: vision candidate evidence retained in $run_dir"
