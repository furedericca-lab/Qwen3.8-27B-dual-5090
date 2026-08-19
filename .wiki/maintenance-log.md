---
title: Qwen3.8-27B Maintenance Log
type: reference
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [.wiki]
code_anchors: []
source_docs: [.scopes/archive/qwen38-27b-dual-5090-deployment]
tags: [maintenance, deployment]
last_checked: 2026-08-19
updated: 2026-08-19T13:06:00Z
---

# Maintenance Log

## 2026-08-17

- Initialized the deployment-only repository.
- Added the official llama.cpp submodule pin.
- Recorded the production GGUF identity and parsed metadata.
- Built upstream llama.cpp `34af94cd9` with CUDA 13.3.73 for both RTX 5090 devices.
- Accepted 32K smoke, 128K F16-KV long-context retrieval, isolated PP/TG benchmark, and a 20-turn tool-call soak on a clean host boot.
- Removed the retired DeepSeek and Qwen3.6 local projects and the old Qwen3.6 GGUF under explicit user authorization; the production Qwen3.8 GGUF remains unchanged.

## 2026-08-19 [qwen38-mtp-production]

- Replaced the deleted non-MTP artifact with the sole Q8_0 MTP GGUF, SHA256 `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748`, mode `0444`.
- Verified Qwen35 metadata, one NextN prediction layer, and four `blk.64.nextn.*` tensors.
- Accepted canonical 128K layer-split `draft-mtp` with draft depth 2: basic probe, 130,090-token retrieval, 20-turn tool soak, server metrics, and post-run host-integrity gate passed.
- Recorded MTP acceptance of 67.14% (4,719 accepted of 7,029 drafted) and measured 91.95-98.41 tok/s across the server workloads.
