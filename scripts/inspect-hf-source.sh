#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
pin_file="$root/evidence/hf-source.txt"
hash_file="$root/evidence/model.sha256"
fail=0

test -f "$pin_file" || { echo "FAIL: missing $pin_file" >&2; exit 1; }
test -f "$hash_file" || { echo "FAIL: missing $hash_file" >&2; exit 1; }

before=$(sha256sum "$pin_file")
declare -A pin=()
while IFS= read -r line; do
  [[ -z $line || $line == \#* ]] && continue
  key=${line%%=*}
  value=${line#*=}
  pin[$key]=$value
done < "$pin_file"

required=(hf_repo hf_file hf_pinned_revision hf_lfs_sha256 hf_size_bytes local_path)
for key in "${required[@]}"; do
  [[ -n ${pin[$key]:-} ]] || { echo "FAIL: $pin_file missing $key" >&2; exit 1; }
done

local_hash=$(awk 'NF && $1 !~ /^#/ {print $1; exit}' "$hash_file")
local_path=$(awk 'NF && $1 !~ /^#/ {print $2; exit}' "$hash_file")
local_size=$(stat -c '%s' "${pin[local_path]}")

if [[ ${pin[hf_lfs_sha256]} != "$local_hash" ]]; then
  echo "FAIL: pinned HF SHA ${pin[hf_lfs_sha256]} != frozen local SHA $local_hash" >&2
  fail=1
fi
if [[ ${pin[local_path]} != "$local_path" ]]; then
  echo "FAIL: pinned path ${pin[local_path]} != frozen hash path $local_path" >&2
  fail=1
fi
if [[ ${pin[hf_size_bytes]} != "$local_size" ]]; then
  echo "FAIL: pinned size ${pin[hf_size_bytes]} != local size $local_size" >&2
  fail=1
fi

fetch_identity() {
  local rev=$1
  curl -fsSI --max-time 30 \
    "https://huggingface.co/${pin[hf_repo]}/resolve/${rev}/${pin[hf_file]}" \
    | python3 -c '
import sys
raw = sys.stdin.read().replace("\r", "")
headers = {}
for line in raw.splitlines():
    if ":" not in line:
        continue
    key, value = line.split(":", 1)
    headers[key.strip().lower()] = value.strip()
etag = (headers.get("x-linked-etag") or headers.get("etag") or "").strip("\"")
size = headers.get("x-linked-size") or ""
commit = headers.get("x-repo-commit") or ""
print(etag)
print(size)
print(commit)
'
}

mapfile -t pinned_id < <(fetch_identity "${pin[hf_pinned_revision]}")
pinned_remote_sha=${pinned_id[0]:-}
pinned_remote_size=${pinned_id[1]:-}
pinned_remote_commit=${pinned_id[2]:-}

head_rev=$(curl -fsSL --max-time 30 "https://huggingface.co/api/models/${pin[hf_repo]}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["sha"])')
mapfile -t head_id < <(fetch_identity "$head_rev")
head_remote_sha=${head_id[0]:-}
head_remote_size=${head_id[1]:-}
head_remote_commit=${head_id[2]:-}

printf 'hf_repo=%s\n' "${pin[hf_repo]}"
printf 'hf_file=%s\n' "${pin[hf_file]}"
printf 'hf_pinned_revision=%s\n' "${pin[hf_pinned_revision]}"
printf 'hf_head_revision=%s\n' "$head_rev"
printf 'hf_pinned_remote_sha=%s\n' "$pinned_remote_sha"
printf 'hf_head_remote_sha=%s\n' "$head_remote_sha"
printf 'hf_pinned_remote_size=%s\n' "$pinned_remote_size"
printf 'hf_head_remote_size=%s\n' "$head_remote_size"
printf 'hf_pinned_remote_commit=%s\n' "$pinned_remote_commit"
printf 'hf_head_remote_commit=%s\n' "$head_remote_commit"
printf 'local_sha=%s\n' "$local_hash"
printf 'local_size=%s\n' "$local_size"

if [[ $pinned_remote_sha != "${pin[hf_lfs_sha256]}" ]]; then
  echo "FAIL: pinned revision remote SHA ${pinned_remote_sha:-missing} != ${pin[hf_lfs_sha256]}" >&2
  fail=1
fi
if [[ $pinned_remote_size != "${pin[hf_size_bytes]}" ]]; then
  echo "FAIL: pinned revision remote size ${pinned_remote_size:-missing} != ${pin[hf_size_bytes]}" >&2
  fail=1
fi
head_status=match
if [[ $head_remote_sha == "${pin[hf_lfs_sha256]}" && $head_remote_size == "${pin[hf_size_bytes]}" ]]; then
  if [[ $head_rev != "${pin[hf_pinned_revision]}" ]]; then
    head_status=revision-only
    echo "WARN: HF HEAD revision $head_rev differs from pin ${pin[hf_pinned_revision]}; file SHA still matches" >&2
  fi
else
  head_status=file-drift
  echo "FAIL: HF HEAD file identity drifted from the pinned GGUF" >&2
  echo "FAIL: keep evidence/hf-source.txt; do not auto-promote HEAD $head_rev SHA ${head_remote_sha:-missing} size ${head_remote_size:-missing}" >&2
  fail=1
fi
printf 'hf_head_status=%s\n' "$head_status"

after=$(sha256sum "$pin_file")
[[ $before == "$after" ]] || { echo "FAIL: $pin_file changed during inspect" >&2; exit 1; }

if (( fail )); then
  echo 'FAIL: HF source gate' >&2
  exit 1
fi
echo 'PASS: HF source matches frozen local GGUF'
