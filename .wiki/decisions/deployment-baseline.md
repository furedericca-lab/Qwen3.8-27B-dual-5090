---
title: Deployment Baseline
type: decision
status: accepted
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/llama-server.sh, AGENTS.md]
code_anchors: []
source_docs: [.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-implementation-research-notes.md]
tags: [baseline, llama-cpp, runtime]
decision_date: 2026-08-17
last_checked: 2026-08-17
updated: 2026-08-17T15:15:00Z
---

# Deployment Baseline

The first runtime is a conservative 32K smoke. It uses the same F16 KV, single-slot, Flash Attention, direct-I/O, automatic two-GPU layer fitting, and 4096 MiB per-device fit margin intended for the later 128K baseline.

Only `PROFILE=baseline` exists until benchmark evidence justifies an `agent` or `long` profile. The default 32K context prevents an unverified 128K claim.

The production model is Q8_0 only. The GGUF has no embedded chat template, so the launcher supplies the pinned upstream `models/templates/Qwen3.5-4B.jinja` template after a 128K tool-call A/B passed. No conversion, quantization, MTP, CPU offload, vLLM route, or sampler profile is part of this baseline.
