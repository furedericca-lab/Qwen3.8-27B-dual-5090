#!/usr/bin/env bash
set -euo pipefail

model=/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf
fail=0

findmnt -T "$model" -o TARGET,SOURCE,FSTYPE,OPTIONS
filesystem=$(findmnt -n -T "$model" -o FSTYPE)
if [[ $filesystem != ext4 ]]; then
  echo "FAIL: production model is not on ext4: $filesystem" >&2
  fail=1
fi
if [[ $(stat -c '%a' "$model") != 444 ]]; then
  echo "FAIL: production model must be mode 0444" >&2
  fail=1
fi

taint=$(cat /proc/sys/kernel/tainted)
printf 'kernel=%s\nkernel_tainted=%s\n' "$(uname -r)" "$taint"
if [[ $taint != 0 && $taint != 4096 ]]; then
  echo "FAIL: unexpected kernel taint: $taint" >&2
  fail=1
fi

kernel_events=$(journalctl -k -b --no-pager | rg -i 'BAD_PAGE|Oops|general protection|page corruption|NVRM.*Xid|Xid.*NVRM' || true)
if [[ -n $kernel_events ]]; then
  printf 'FAIL: host-integrity kernel events:\n%s\n' "$kernel_events" >&2
  fail=1
fi

nvidia-smi --query-gpu=index,name,driver_version,memory.total,memory.used,memory.free --format=csv,noheader
free -h
swapon --show

if (( fail )); then
  exit 1
fi
echo 'PASS: preflight gate'
