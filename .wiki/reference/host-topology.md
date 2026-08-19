---
title: Dual 5090 PCIe Topology
type: reference
status: current
scope: qwen38-runtime-tuning
related_scopes:
  - qwen38-27b-dual-5090-deployment
related_files:
  - scripts/inspect-topology.sh
  - scripts/llama-server.sh
source_docs:
  - AGENTS.md
tags:
  - topology
  - pcie
  - p2p
last_checked: 2026-08-19
updated: 2026-08-19T13:36:51Z
---

# Dual 5090 PCIe Topology

Observed on this host:

- GPU0 `0000:01:00.0`, GPU1 `0000:02:00.0`
- `nvidia-smi topo -m` GPU0-GPU1 path: PHB (PCIe Host Bridge / CPU)
- `nvidia-smi topo -p2p r`: GNS (GPU not supported)
- Both cards advertise PCIe Generation max 5 / width max 16x, host max 5
- Idle current: Generation 1 / 8x
- Under MTP candidate load: Generation 5 / 8x on both cards (`evidence/candidate-p-min-0p60-20260819T134206Z` and later runs)
- No NVLink

Generation idle-downclocks; link **width stays 8x under load** even though the cap is 16x. That is a real host path, not only ASPM. GeForce 5090 P2P is not available here, so layer-split decode pays a CPU-bridged x8 hop between GPU0 and GPU1. That is expected and is not a reason to switch production to tensor split. Re-run `scripts/inspect-topology.sh` with dual-GPU evidence and compare load current width, not only idle gen.
