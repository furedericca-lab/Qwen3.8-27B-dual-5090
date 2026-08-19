#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
model_dir=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF
expected_model="$model_dir/RVN-Q8_0-mtp.gguf"
hash_file="$root/evidence/model.sha256"

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
test -f "$hash_file" || { echo "FAIL: missing frozen hash file $hash_file" >&2; exit 1; }

expected_hash=$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$hash_file")
expected_path=$(awk 'NF && $1 !~ /^#/ {print $2; exit}' "$hash_file")
[[ -n $expected_hash && -n $expected_path ]] || { echo "FAIL: $hash_file is empty or malformed" >&2; exit 1; }
[[ $expected_path == "$model" ]] || {
  echo "FAIL: frozen hash path $expected_path does not match $model" >&2
  exit 1
}

before=$(sha256sum "$hash_file")
sha256sum -c "$hash_file"
after=$(sha256sum "$hash_file")
[[ $before == "$after" ]] || { echo "FAIL: $hash_file changed during inspect" >&2; exit 1; }

stat -c 'path=%n size=%s mode=%a owner=%U:%G' "$model"

python3 - "$model" <<'PY'
import struct
import sys

path = sys.argv[1]
value_readers = {
    0: ('<B', 1),
    1: ('<b', 1),
    2: ('<H', 2),
    3: ('<h', 2),
    4: ('<I', 4),
    5: ('<i', 4),
    6: ('<f', 4),
    7: ('<B', 1),
    10: ('<Q', 8),
    11: ('<q', 8),
    12: ('<d', 8),
}
ggml_types = {0: 'F32', 8: 'Q8_0'}

with open(path, 'rb') as fh:
    magic, version, n_tensors, n_kv = struct.unpack('<I I Q Q', fh.read(24))
    if magic != 0x46554747:
        raise SystemExit('FAIL: not a GGUF file')

    def read_string():
        (length,) = struct.unpack('<Q', fh.read(8))
        return fh.read(length).decode('utf-8')

    def read_value(kind):
        if kind == 8:
            return read_string()
        if kind == 9:
            (item_kind,) = struct.unpack('<I', fh.read(4))
            (count,) = struct.unpack('<Q', fh.read(8))
            return [read_value(item_kind) for _ in range(count)]
        spec = value_readers.get(kind)
        if spec is None:
            raise SystemExit(f'FAIL: unsupported GGUF value type {kind}')
        fmt, size = spec
        (value,) = struct.unpack(fmt, fh.read(size))
        return bool(value) if kind == 7 else value

    fields = {}
    for _ in range(n_kv):
        key = read_string()
        (kind,) = struct.unpack('<I', fh.read(4))
        fields[key] = read_value(kind)

    tensors = []
    for _ in range(n_tensors):
        name = read_string()
        (n_dims,) = struct.unpack('<I', fh.read(4))
        dims = struct.unpack('<' + 'Q' * n_dims, fh.read(8 * n_dims))
        (tensor_type,) = struct.unpack('<I', fh.read(4))
        fh.read(8)  # offset
        tensors.append((name, dims, tensor_type))

keys = ('general.architecture', 'general.name', 'general.size_label', 'general.file_type', 'general.quantization_version')
suffixes = ('.block_count', '.context_length', '.embedding_length', '.attention.head_count', '.attention.head_count_kv', '.attention.key_length', '.attention.value_length', '.full_attention_interval', '.nextn_predict_layers')
for key in keys:
    if key in fields:
        print(f'{key}={fields[key]!r}')
for key in sorted(fields):
    if key.endswith(suffixes) or 'chat_template' in key:
        print(f'{key}={fields[key]!r}')
mtp_tensors = [
    tensor for tensor in tensors
    if any(part in tensor[0] for part in ('.mtp.', '.nextn.')) or tensor[0].startswith(('mtp.', 'nextn.'))
]
print(f'tensor_count={len(tensors)}')
print(f'nextn_mtp_tensor_count={len(mtp_tensors)}')
for name, dims, tensor_type in mtp_tensors:
    type_name = ggml_types.get(tensor_type, str(tensor_type))
    print(f'nextn_mtp_tensor name={name!r} shape={list(dims)!r} type={type_name}')
if not mtp_tensors:
    raise SystemExit('FAIL: no MTP/NextN tensors found')
PY
