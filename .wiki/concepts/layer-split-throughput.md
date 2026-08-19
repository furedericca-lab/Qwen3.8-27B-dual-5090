---
title: Layer Split Throughput
type: concept
status: current
scope: qwen38-runtime-tuning
related_scopes:
  - qwen38-27b-dual-5090-deployment
related_files:
  - scripts/llama-server.sh
source_docs:
  - AGENTS.md
tags:
  - layer-split
  - mtp
  - throughput
last_checked: 2026-08-19
updated: 2026-08-19T13:36:51Z
---

# Layer Split Throughput

Production uses llama.cpp `--split-mode layer`: layers and KV are pipelined across GPUs. One decode token walks GPU0 layers, then GPU1 layers. It is not same-layer weight parallelism, so two 1792 GB/s 5090s do not become 3.5 TB/s for a single token.

That is why the accepted dual-5090 MTP server result (~95 tok/s) sits next to the author dual RTX PRO 6000 Blackwell Q8_0 MTP number (~98 tok/s). The second 5090 is first a capacity card: Q8_0 MTP plus 128K F16 KV plus compute buffers does not sit comfortably on one 32 GB device.

Do not expect 150-200 tok/s from this dense-hybrid Q8_0 at one slot and layer split. On this host the inter-GPU path is PHB plus P2P `GNS`, and the load link stays PCIe gen5 **x8**. Tensor split remains out of scope. Measured 2026-08-19 MTP server candidates kept production `p-min 0` and `-ub 256` as the throughput winners; see `.wiki/reference/runtime-tuning-results.md`.
