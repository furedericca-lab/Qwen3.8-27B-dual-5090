#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
model_dir=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF
expected_model="$model_dir/RVN-Q8_0.gguf"

if [[ -n ${MODEL:-} ]]; then
  model=$MODEL
else
  mapfile -t candidates < <(find "$model_dir" -maxdepth 1 -type f -name '*Q8_0*.gguf' -printf '%p\n' | sort)
  case ${#candidates[@]} in
    0) echo "FAIL: no Q8_0 GGUF found in $model_dir" >&2; exit 1 ;;
    1) model=${candidates[0]} ;;
    *) printf 'FAIL: multiple Q8_0 GGUF candidates; set MODEL explicitly:\n%s\n' "${candidates[@]}" >&2; exit 1 ;;
  esac
fi

[[ $model == "$expected_model" ]] || { echo "FAIL: production model must be $expected_model" >&2; exit 1; }
test -f "$model" || { echo "FAIL: model does not exist: $model" >&2; exit 1; }

sha256=$(sha256sum "$model" | awk '{print $1}')
printf '%s  %s\n' "$sha256" "$model" | tee "$root/evidence/model.sha256"
stat -c 'path=%n%nsize=%s%nmode=%a%nowner=%U:%G' "$model"

PYTHONPATH="$root/llama.cpp/gguf-py${PYTHONPATH:+:$PYTHONPATH}" python3 - "$model" <<'PY'
from gguf import GGUFReader
from pathlib import Path
import sys

model = Path(sys.argv[1])
reader = GGUFReader(model, 'r')
keys = ('general.architecture', 'general.name', 'general.size_label', 'general.file_type', 'general.quantization_version')
suffixes = ('.block_count', '.context_length', '.embedding_length', '.attention.head_count', '.attention.head_count_kv', '.attention.key_length', '.attention.value_length', '.full_attention_interval', '.nextn_predict_layers')
for key in keys:
    if key in reader.fields:
        print(f'{key}={reader.fields[key].contents()!r}')
for key in sorted(reader.fields):
    if key.endswith(suffixes) or 'chat_template' in key:
        print(f'{key}={reader.fields[key].contents()!r}')
mtp_tensors = sum('.mtp.' in tensor.name or tensor.name.startswith('mtp.') for tensor in reader.tensors)
print(f'tensor_count={len(reader.tensors)}')
print(f'mtp_tensor_count={mtp_tensors}')
PY
