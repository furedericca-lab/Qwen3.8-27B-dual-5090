#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
server="$root/llama.cpp/build/bin/llama-server"
model_dir=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF
model="$model_dir/RVN-Q8_0-multilingual-mtp.gguf"
mmproj="$model_dir/mmproj-Qwen3.8-27B-Q8_0.gguf"
chat_template="$model_dir/chat_template.jinja"
profile=${PROFILE:-agent}
port=${PORT:-8000}
host=${HOST:-127.0.0.1}

case "$profile" in
  baseline) context=32768 ;;
  agent) context=262144 ;;
  *) echo "PROFILE must be baseline or agent" >&2; exit 1 ;;
esac
[[ ${CONTEXT:-$context} == "$context" ]] || { echo "CONTEXT is fixed by PROFILE" >&2; exit 1; }
test -x "$server" || { echo "missing built llama-server; run scripts/build-llama.sh" >&2; exit 1; }
"$root/scripts/preflight.sh"

exec "$server" \
  -m "$model" \
  --mmproj "$mmproj" \
  --load-mode dio \
  -dev CUDA0,CUDA1 \
  -sm layer \
  --fit on \
  --fit-target 2048,2048 \
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
  --chat-template-file "$chat_template" \
  --host "$host" \
  --port "$port"
