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
last_checked: 2026-08-17
updated: 2026-08-17T15:30:00Z
---

# Maintenance Log

## 2026-08-17

- Initialized the deployment-only repository.
- Added the official llama.cpp submodule pin.
- Recorded the production GGUF identity and parsed metadata.
- Built upstream llama.cpp `34af94cd9` with CUDA 13.3.73 for both RTX 5090 devices.
- Accepted 32K smoke, 128K F16-KV long-context retrieval, isolated PP/TG benchmark, and a 20-turn tool-call soak on a clean host boot.
- Removed the retired DeepSeek and Qwen3.6 local projects and the old Qwen3.6 GGUF under explicit user authorization; the production Qwen3.8 GGUF remains unchanged.
