#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
service_name=qwen38-27b.service
unit_source="$root/systemd/$service_name"
unit_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
unit_target="$unit_dir/$service_name"

test -f "$unit_source" || { echo "missing service unit: $unit_source" >&2; exit 1; }
mkdir -p "$unit_dir"

if [[ -e "$unit_target" || -L "$unit_target" ]]; then
  resolved=$(readlink -f "$unit_target")
  [[ "$resolved" == "$unit_source" ]] || {
    echo "refusing to replace existing unit: $unit_target -> $resolved" >&2
    exit 1
  }
else
  ln -s "$unit_source" "$unit_target"
fi

systemctl --user daemon-reload
printf 'Installed %s\n' "$unit_target"
printf 'Start: systemctl --user start %s\n' "$service_name"
printf 'Stop:  systemctl --user stop %s\n' "$service_name"
printf 'Logs:  journalctl --user -u %s -f\n' "$service_name"
