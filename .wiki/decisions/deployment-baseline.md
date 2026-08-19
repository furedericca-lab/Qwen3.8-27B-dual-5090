---
title: Deployment Baseline
type: decision
status: accepted
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment, qwen38-runtime-tuning]
related_files: [scripts/llama-server.sh, AGENTS.md]
code_anchors: []
source_docs: [.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-implementation-research-notes.md]
tags: [baseline, llama-cpp, runtime]
decision_date: 2026-08-17
last_checked: 2026-08-19
updated: 2026-08-19T13:06:00Z
---

# Deployment Baseline

The accepted production `agent` profile is 128K and uses F16 KV, one slot, Flash Attention, direct I/O, automatic two-GPU layer fitting, a 4096 MiB per-device fit margin, and MTP speculative decoding.

`PROFILE=agent` is the default after a 130,090-token retrieval within a 131,072-token slot, isolated PP/TG, a 20-turn tool-call soak, and MTP metric validation passed. `PROFILE=baseline` retains the 32K smoke configuration.

The production model is the Q8_0 MTP GGUF only. It has one NextN prediction layer and uses `draft-mtp` with accepted draft depth 3 under layer split. The launcher supplies the pinned upstream `models/templates/Qwen3.5-4B.jinja` template. No conversion, quantization, CPU offload, vLLM route, tensor split, draft model, or ngram speculative mode is part of this baseline.

Runtime knobs such as `--spec-draft-p-min` and ubatch remain production-frozen until a candidate run under `.scopes/qwen38-runtime-tuning` beats this baseline and a separate production-change scope promotes it. Dual-5090 layer split is a capacity/residency choice, not a 2x single-token bandwidth path.
