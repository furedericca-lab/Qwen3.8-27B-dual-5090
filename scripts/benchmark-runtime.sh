#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
bench="$root/llama.cpp/build/bin/llama-bench"
model=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-multilingual-mtp.gguf
run_dir="$root/evidence/benchmark-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$run_dir"
test -x "$bench" || { echo "missing llama-bench; run scripts/build-llama.sh" >&2; exit 1; }
if pgrep -f '^.*/llama-server( |$)' >/dev/null; then
  echo "refusing benchmark while llama-server is running; stop it first" >&2
  exit 1
fi
"$root/scripts/preflight.sh" | tee "$run_dir/preflight.txt"

{
  printf 'model_sha256='
  awk '{print $1}' "$root/evidence/model.sha256"
  printf 'llama_cpp_sha='
  git -C "$root/llama.cpp" rev-parse HEAD
  printf 'cuda='
  nvcc --version | tail -n 1
  printf 'kernel='
  uname -r
} | tee "$run_dir/environment.txt"
nvidia-smi --query-gpu=index,name,memory.used,memory.free,power.draw --format=csv,noheader | tee "$run_dir/gpu-before.csv"

nvidia-smi --query-gpu=index,name,memory.used,memory.free,power.draw --format=csv,noheader -l 1 \
  >"$run_dir/gpu-samples.csv" &
sampler_pid=$!
cleanup() {
  kill "$sampler_pid" 2>/dev/null || true
  wait "$sampler_pid" 2>/dev/null || true
}
trap cleanup EXIT

"$bench" -m "$model" --load-mode dio -dev CUDA0/CUDA1 -sm layer \
  --fit-target 4096 -ctk f16 -ctv f16 -fa on \
  -p 512,4096,32768 -n 128 -b 1024 -ub 256 -o jsonl | tee "$run_dir/llama-bench.jsonl"

cleanup
trap - EXIT

nvidia-smi --query-gpu=index,name,memory.used,memory.free,power.draw --format=csv,noheader | tee "$run_dir/gpu-after.csv"
free -h | tee "$run_dir/memory-after.txt"
echo "PASS: benchmark evidence retained in $run_dir"
