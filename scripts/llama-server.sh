#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
server="$root/llama.cpp/build/bin/llama-server"
model=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0.gguf
profile=${PROFILE:-baseline}
context=${CONTEXT:-32768}
port=${PORT:-8000}

[[ $profile == baseline ]] || { echo "only PROFILE=baseline is defined" >&2; exit 1; }
[[ $context =~ ^(32768|131072)$ ]] || { echo "CONTEXT must be 32768 or 131072" >&2; exit 1; }
test -x "$server" || { echo "missing built llama-server; run scripts/build-llama.sh" >&2; exit 1; }
"$root/scripts/preflight.sh"

exec "$server" \
  -m "$model" \
  --load-mode dio \
  -dev CUDA0,CUDA1 \
  -sm layer \
  --fit on \
  --fit-target 4096,4096 \
  -ctk f16 \
  -ctv f16 \
  -c "$context" \
  -np 1 \
  -b 1024 \
  -ub 256 \
  -fa on \
  --host 127.0.0.1 \
  --port "$port"
