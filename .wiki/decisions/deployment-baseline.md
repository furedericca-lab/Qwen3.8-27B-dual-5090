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
last_checked: 2026-08-20
updated: 2026-08-20T13:50:00Z
---

# Deployment Baseline

The accepted production `agent` profile is 256K and uses F16 KV, one slot, Flash Attention, direct I/O, automatic two-GPU layer fitting, a 4096 MiB per-device fit margin, and MTP speculative decoding.

`PROFILE=agent` is the default after a 261,160-token retrieval within a 262,144-token slot, a 20-turn tool-call soak, and MTP metric validation passed on `RVN-Q8_0-multilingual-mtp.gguf`. `PROFILE=baseline` retains the 32K smoke configuration.

The production model is `RVN-Q8_0-multilingual-mtp.gguf` only. It has one NextN prediction layer and uses `draft-mtp` with accepted draft depth 3 under layer split. The launcher supplies the pinned upstream `models/templates/Qwen3.5-4B.jinja` template. No conversion, quantization, CPU offload, vLLM route, tensor split, draft model, or ngram speculative mode is part of this baseline.

`--spec-draft-p-min` remains omitted (effective 0) and `-ub 256` remains frozen. Draft depth 3 was promoted after the n-max=3 candidate win recorded in [runtime-tuning-freeze](runtime-tuning-freeze.md). Dual-5090 layer split is a capacity/residency choice, not a 2x single-token bandwidth path. Identity is pinned in [hf-source](../reference/hf-source.md); do not auto-promote a later HEAD replacement of this filename.
