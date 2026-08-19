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

## 2026-08-19T13:39:17Z [qwen38-runtime-tuning]

- Summary: Pinned HF revision and LFS SHA; verify-only inspect.
- Pages: .wiki/reference/hf-source.md
- Verification: scripts/inspect-hf-source.sh

## 2026-08-19T13:54:04Z [qwen38-runtime-tuning]

- Summary: Recorded p-min and ubatch MTP candidate results; production defaults kept.
- Pages: .wiki/reference/runtime-tuning-results.md
- Verification: scripts/run-mtp-candidate.sh

## 2026-08-19T14:55:00Z [ubatch-and-mtp-n3]

- Long-prompt PP selected `-b 1024 -ub 256`: +37.25%, +26.47%, and +7.13% versus ub=128 at the 32K, 64K, and 128K envelopes; ub=512 was slower and used more VRAM.
- Draft depth 3 with p-min 0 improved short/medium/long TG by 8.03%, 6.49%, and 6.61% over the n=2 baseline while preserving completion lengths and finish reasons.
- Promoted n-max 3 after basic responses, 130,090-token retrieval, 20-turn tool-call soak, and post-run host-integrity gate passed.
