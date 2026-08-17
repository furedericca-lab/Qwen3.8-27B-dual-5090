---
title: VRAM Budget
type: reference
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/llama-server.sh, scripts/benchmark-runtime.sh]
code_anchors: []
source_docs: [.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-scope-milestones.md]
tags: [vram, fit-target, dual-5090]
last_checked: 2026-08-17
updated: 2026-08-17T15:15:00Z
---

# VRAM Budget

No Qwen3.6 memory numbers are reused here. The initial two-GPU fitting target is 4096 MiB on each RTX 5090 and must be evaluated using the minimum free VRAM after model load and workload setup:

```text
min(GPU0 free, GPU1 free)
```

The order for capacity pressure is smaller ubatch, larger fit target, KV type, then lower context. CPU offload requires an explicit scope.
