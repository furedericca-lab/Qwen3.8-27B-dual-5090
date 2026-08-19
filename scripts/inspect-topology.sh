#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
stamp=$(date -u +%Y%m%dT%H%M%SZ)
run_dir=${1:-"$root/evidence/host-topology-$stamp"}
mkdir -p "$run_dir"

strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g'
}

{
  echo "timestamp_utc=$stamp"
  echo "kernel=$(uname -r)"
  nvidia-smi --query-gpu=index,name,driver_version,pci.bus_id,pcie.link.gen.max,pcie.link.gen.current,pcie.link.width.max,pcie.link.width.current,memory.total --format=csv
  echo
  echo '=== nvidia-smi topo -m ==='
  nvidia-smi topo -m | strip_ansi
  echo
  echo '=== nvidia-smi topo -p2p r ==='
  nvidia-smi topo -p2p r | strip_ansi
  echo
  echo '=== nvidia-smi PCI ==='
  python3 - <<'PY'
import subprocess
text = subprocess.check_output(['nvidia-smi', '-q'], text=True)
blocks = text.split('\nGPU 0000')
print(blocks[0].split('Attached GPUs')[0].strip())
for block in blocks[1:]:
    lines = block.splitlines()
    capture = False
    for line in lines:
        if line.strip() == 'PCI':
            capture = True
        if capture:
            print(line)
        if capture and line.strip().startswith('Fan Speed'):
            break
    print()
PY
  echo
  echo '=== lspci NVIDIA VGA Lnk ==='
  while read -r slot; do
    echo "-- $slot --"
    lspci -vv -s "$slot" | rg -e 'VGA compatible controller' -e 'LnkCap:' -e 'LnkSta:' -e 'LnkCtl:' || true
  done < <(lspci -d 10de: -nn | awk '/VGA compatible controller/ {print $1}')
} | tee "$run_dir/topology.txt"

gpu_count=$(nvidia-smi --query-gpu=index --format=csv,noheader | wc -l)
if [[ $gpu_count -ne 2 ]]; then
  echo "FAIL: expected 2 GPUs, found $gpu_count" >&2
  exit 1
fi
echo "PASS: topology snapshot retained in $run_dir"
