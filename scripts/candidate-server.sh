#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
server="$root/llama.cpp/build/bin/llama-server"
model=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-multilingual-mtp.gguf
profile=${PROFILE:-agent}
port=${PORT:-8000}
draft_n_max=${DRAFT_N_MAX:-3}
changed=${1:-}
value=${2:-}

usage() {
  echo "usage: PROFILE=agent scripts/candidate-server.sh <p-min|ubatch|fit-target|context> <value>" >&2
  exit 2
}

[[ -n $changed && -n $value ]] || usage
[[ $draft_n_max == 2 || $draft_n_max == 3 ]] || { echo "DRAFT_N_MAX must be 2 or 3" >&2; exit 1; }
case "$profile" in
  baseline) context=32768 ;;
  agent) context=262144 ;;
  *) echo "PROFILE must be baseline or agent" >&2; exit 1 ;;
esac
[[ ${CONTEXT:-$context} == "$context" ]] || { echo "CONTEXT is fixed by PROFILE" >&2; exit 1; }
test -x "$server" || { echo "missing built llama-server; run scripts/build-llama.sh" >&2; exit 1; }

ubatch=256
fit_target=4096,4096
extra=()
case "$changed" in
  p-min)
    extra+=(--spec-draft-p-min "$value")
    ;;
  ubatch)
    ubatch=$value
    ;;
  fit-target)
    fit_target=$value
    ;;
  context)
    case "$value" in
      131072|262144) context=$value ;;
      *) echo "FAIL: context must be 131072 or 262144" >&2; exit 1 ;;
    esac
    ;;
  *)
    echo "FAIL: unsupported changed variable $changed" >&2
    usage
    ;;
esac

"$root/scripts/preflight.sh"
echo "candidate_changed_variable=$changed"
echo "candidate_value=$value"

exec "$server" \
  -m "$model" \
  --load-mode dio \
  -dev CUDA0,CUDA1 \
  -sm layer \
  --fit on \
  --fit-target "$fit_target" \
  -ctk f16 \
  -ctv f16 \
  -c "$context" \
  -np 1 \
  -b 1024 \
  -ub "$ubatch" \
  -fa on \
  --spec-type draft-mtp \
  --spec-draft-n-max "$draft_n_max" \
  --metrics \
  --chat-template-file "$root/llama.cpp/models/templates/Qwen3.5-4B.jinja" \
  --host 127.0.0.1 \
  --port "$port" \
  "${extra[@]}"
