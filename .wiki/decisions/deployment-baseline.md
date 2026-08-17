---
title: Deployment Baseline
type: decision
status: accepted
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/llama-server.sh, AGENTS.md]
code_anchors: []
source_docs: [.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-implementation-research-notes.md]
tags: [baseline, llama-cpp, runtime]
decision_date: 2026-08-17
last_checked: 2026-08-17
updated: 2026-08-17T15:30:00Z
---

# Deployment Baseline

The first runtime was a conservative 32K smoke. The accepted production `agent` profile is 128K and uses F16 KV, one slot, Flash Attention, direct I/O, automatic two-GPU layer fitting, and a 4096 MiB per-device fit margin.

`PROFILE=agent` is the default after 128K retrieval, isolated PP/TG, and a 20-turn tool-call soak passed. `PROFILE=baseline` retains the 32K smoke configuration. A `long` profile remains undefined because no 256K candidate has been accepted.

The production model is Q8_0 only. The GGUF has no embedded chat template, so the launcher supplies the pinned upstream `models/templates/Qwen3.5-4B.jinja` template after a 128K tool-call A/B passed. No conversion, quantization, MTP, CPU offload, vLLM route, or sampler profile is part of this baseline.
