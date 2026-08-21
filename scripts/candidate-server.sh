#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
server="$root/llama.cpp/build/bin/llama-server"
model_dir=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF
model="$model_dir/RVN-Q8_0-multilingual-mtp.gguf"
mmproj="$model_dir/mmproj-Qwen3.8-27B-Q8_0.gguf"
hf_chat_template="$model_dir/chat_template.jinja"
upstream_chat_template="$root/llama.cpp/models/templates/Qwen3.5-4B.jinja"
profile=${PROFILE:-agent}
port=${PORT:-8000}
draft_n_max=${DRAFT_N_MAX:-3}
changed=${1:-}
value=${2:-}
template_mode=${TEMPLATE:-upstream}

usage() {
  echo "usage: PROFILE=agent scripts/candidate-server.sh <p-min|ubatch|fit-target|context|template|mmproj> <value>" >&2
  echo "       TEMPLATE=hf ... mmproj on   # combine an accepted HF template with mmproj" >&2
  exit 2
}

[[ -n $changed && -n $value ]] || usage
[[ $draft_n_max == 2 || $draft_n_max == 3 ]] || { echo "DRAFT_N_MAX must be 2 or 3" >&2; exit 1; }
[[ $template_mode == upstream || $template_mode == hf ]] || { echo "TEMPLATE must be upstream or hf" >&2; exit 1; }
case "$profile" in
  baseline) context=32768 ;;
  agent) context=262144 ;;
  *) echo "PROFILE must be baseline or agent" >&2; exit 1 ;;
esac
[[ ${CONTEXT:-$context} == "$context" ]] || { echo "CONTEXT is fixed by PROFILE" >&2; exit 1; }
test -x "$server" || { echo "missing built llama-server; run scripts/build-llama.sh" >&2; exit 1; }

ubatch=256
fit_target=2048,2048
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
  template)
    [[ $value == hf ]] || { echo "FAIL: template candidate value must be hf" >&2; exit 1; }
    template_mode=hf
    ;;
  mmproj)
    [[ $value == on ]] || { echo "FAIL: mmproj candidate value must be on" >&2; exit 1; }
    test -f "$mmproj" || { echo "missing pinned mmproj: $mmproj" >&2; exit 1; }
    extra+=(--mmproj "$mmproj")
    ;;
  *)
    echo "FAIL: unsupported changed variable $changed" >&2
    usage
    ;;
esac

if [[ $template_mode == hf ]]; then
  test -f "$hf_chat_template" || { echo "missing pinned chat template: $hf_chat_template" >&2; exit 1; }
  chat_template=$hf_chat_template
else
  chat_template=$upstream_chat_template
fi

"$root/scripts/preflight.sh"
echo "candidate_changed_variable=$changed"
echo "candidate_value=$value"
echo "candidate_profile=$profile"
echo "candidate_context=$context"
echo "candidate_fit_target=$fit_target"
echo "candidate_template=$template_mode"
echo "candidate_mmproj=$([[ $changed == mmproj ]] && echo on || echo off)"

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
  --chat-template-file "$chat_template" \
  --host 127.0.0.1 \
  --port "$port" \
  "${extra[@]}"
