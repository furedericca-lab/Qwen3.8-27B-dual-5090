#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
changed=${1:-}
value=${2:-}
port=${PORT:-8000}
base_url="http://127.0.0.1:$port"
profile=${PROFILE:-agent}
draft_n_max=${DRAFT_N_MAX:-3}
candidate_template=${TEMPLATE:-upstream}
[[ $changed == template ]] && candidate_template=hf

[[ -n $changed && -n $value ]] || {
  echo "usage: scripts/run-mtp-candidate.sh <p-min|ubatch|fit-target|context|template|mmproj> <value>" >&2
  exit 2
}

if pgrep -f '^.*/llama-server( |$)' >/dev/null; then
  echo "FAIL: llama-server already running; stop it before a candidate run" >&2
  exit 1
fi

safe_value=${value//./p}
safe_value=${safe_value//,/x}
run_dir="$root/evidence/candidate-${changed}-${safe_value}-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$run_dir"
{
  printf 'changed_variable=%s\n' "$changed"
  printf 'value=%s\n' "$value"
  printf 'profile=%s\n' "$profile"
  printf 'draft_n_max=%s\n' "$draft_n_max"
  printf 'fit_target=2048,2048\n'
  printf 'template=%s\n' "$candidate_template"
  printf 'mmproj_candidate=%s\n' "$([[ $changed == mmproj ]] && echo on || echo off)"
  printf 'model_sha256='
  awk 'NF && $1 !~ /^#/ {print $1; exit}' "$root/evidence/model.sha256"
  printf 'llama_cpp_sha='
  git -C "$root/llama.cpp" rev-parse HEAD
} | tee "$run_dir/config.txt"

"$root/scripts/inspect-topology.sh" "$run_dir"

"$root/scripts/candidate-server.sh" "$changed" "$value" \
  >"$run_dir/server.log" 2>&1 &
server_pid=$!
cleanup() {
  if kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

ok=0
for _ in $(seq 1 180); do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "FAIL: candidate server exited before /health" >&2
    tail -n 80 "$run_dir/server.log" >&2 || true
    exit 1
  fi
  if curl -fsS "$base_url/health" >"$run_dir/health.json" 2>/dev/null; then
    ok=1
    break
  fi
  sleep 2
done
if (( ! ok )); then
  echo "FAIL: candidate server did not become healthy" >&2
  tail -n 80 "$run_dir/server.log" >&2 || true
  exit 1
fi

curl -fsS "$base_url/v1/models" >"$run_dir/models.json"
nvidia-smi --query-gpu=index,name,driver_version,memory.total,memory.used,memory.free --format=csv,noheader >"$run_dir/gpu-startup.csv"
free -h >"$run_dir/memory-startup.txt"
swapon --show >"$run_dir/swap-startup.txt"
RUN_DIR="$run_dir/basic" BASE_URL="$base_url" "$root/scripts/probe-basic.sh" >"$run_dir/basic.log" 2>&1
if [[ $changed == template ]]; then
  "$root/scripts/preflight.sh" >"$run_dir/preflight-before-soak.txt" 2>&1
  python3 "$root/scripts/soak-agent.py" --base-url "$base_url" --turns 20 --run-dir "$run_dir/agent-soak" >"$run_dir/soak.log" 2>&1
fi
"$root/scripts/preflight.sh" >"$run_dir/preflight-before-mtp.txt" 2>&1
python3 "$root/scripts/benchmark-server-mtp.py" --base-url "$base_url" --run-dir "$run_dir/mtp-bench"
cleanup
trap - EXIT
"$root/scripts/preflight.sh" >"$run_dir/preflight-after.txt" 2>&1
echo "PASS: candidate evidence retained in $run_dir"
