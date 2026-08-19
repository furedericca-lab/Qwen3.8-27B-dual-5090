#!/usr/bin/env bash
set -uo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
test_dir=${TEST_DIR:-$root/evidence/ubatch-long-prompt-$timestamp}
contexts=(32768 65536 131072)
ubatches=(128 256 512)
port=${PORT:-18000}
server_pid=

mkdir -p "$test_dir"
results_file=$test_dir/results.csv
echo 'context_tokens,target_prompt_tokens,ubatch,actual_prompt_tokens,prompt_tok_s,server_prompt_ms,ttft_wall_ms,peak_gpu0_mib,peak_gpu1_mib,status' > "$results_file"

cleanup() {
  if [[ -n ${server_pid:-} ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

cat > "$test_dir/config.txt" <<EOF
model=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf
server_context_tokens=131072
batch=1024
ubatches=128 256 512
prompt_contexts=32768 65536 131072
prompt_headroom_tokens=1024
fit_target=4096,4096
load_mode=dio
mtp_draft_n_max=2
EOF

for context in "${contexts[@]}"; do
  target=$((context - 1024))
  for ubatch in "${ubatches[@]}"; do
    run_dir=$test_dir/ctx${context}_ub${ubatch}
    mkdir -p "$run_dir"
    echo "RUN context=$context target=$target ubatch=$ubatch"

    if ! "$root/scripts/preflight.sh" > "$run_dir/preflight.txt" 2>&1; then
      echo "$context,$target,$ubatch,,,,,,,PREFLIGHT_FAILED" >> "$results_file"
      continue
    fi

    PROFILE=agent PORT=$port "$root/scripts/candidate-server.sh" ubatch "$ubatch" > "$run_dir/server.log" 2>&1 &
    server_pid=$!
    ready=0
    for _ in $(seq 1 180); do
      if curl --fail --silent "http://127.0.0.1:$port/health" > "$run_dir/health.json" 2>/dev/null; then
        ready=1
        break
      fi
      if ! kill -0 "$server_pid" 2>/dev/null; then
        break
      fi
      sleep 1
    done
    if (( ! ready )); then
      wait "$server_pid" 2>/dev/null
      status=$?
      echo "$context,$target,$ubatch,,,,,,,SERVER_FAILED_$status" >> "$results_file"
      server_pid=
      continue
    fi

    if "$root/scripts/benchmark-ubatch-prefill.py" \
      --base-url "http://127.0.0.1:$port" \
      --target-tokens "$target" \
      --run-dir "$run_dir" > "$run_dir/benchmark.stdout" 2> "$run_dir/benchmark.stderr"; then
      jq -r --arg context "$context" --arg target "$target" --arg ubatch "$ubatch" \
        '[$context,$target,$ubatch,.actual_prompt_tokens,.prompt_tokens_per_second,.server_prompt_ms,.ttft_wall_ms,.peak_gpu0_mib,.peak_gpu1_mib,"PASS"] | @csv' \
        "$run_dir/summary.json" >> "$results_file"
    else
      status=$?
      result=BENCHMARK_FAILED_$status
      if rg -qi 'out of memory|CUDA error|failed to allocate' "$run_dir/server.log" "$run_dir/benchmark.stderr"; then
        result=OOM
      fi
      echo "$context,$target,$ubatch,,,,,,,$result" >> "$results_file"
    fi

    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
    server_pid=
    sleep 2
  done
done

"$root/scripts/preflight.sh" > "$test_dir/preflight-after.txt" 2>&1 || exit 1
echo "PASS: sweep retained in $test_dir"
