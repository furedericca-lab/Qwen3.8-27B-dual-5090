#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
server="$root/llama.cpp/build/bin/llama-server"
model=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf
profile=${PROFILE:-agent}
port=${PORT:-8000}

case "$profile" in
  baseline) context=32768 ;;
  agent) context=131072 ;;
  *) echo "PROFILE must be baseline or agent" >&2; exit 1 ;;
esac
[[ ${CONTEXT:-$context} == "$context" ]] || { echo "CONTEXT is fixed by PROFILE" >&2; exit 1; }
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
  --spec-type draft-mtp \
  --spec-draft-n-max 3 \
  --metrics \
  --chat-template-file "$root/llama.cpp/models/templates/Qwen3.5-4B.jinja" \
  --host 127.0.0.1 \
  --port "$port"
