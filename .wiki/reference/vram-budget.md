---
title: VRAM Budget
type: reference
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/llama-server.sh, scripts/benchmark-runtime.sh]
code_anchors: []
source_docs: [.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-scope-milestones.md]
tags: [vram, fit-target, dual-5090]
last_checked: 2026-08-17
updated: 2026-08-17T15:30:00Z
---

# VRAM Budget

No Qwen3.6 memory numbers are reused here. The accepted two-GPU fitting target is 4096 MiB on each RTX 5090. The 128K F16-KV server left approximately 14.3 GiB free on GPU0 and 13.6 GiB free on GPU1 after load. The isolated PP/TG benchmark retained in `evidence/benchmark-20260817T152536Z/` observed a 17,563 MiB / 16,632 MiB minimum-free pair at its smaller benchmark contexts.

```text
min(GPU0 free, GPU1 free)
```

Use the minimum of the two cards, not aggregate free VRAM. The order for capacity pressure is smaller ubatch, larger fit target, KV type, then lower context. CPU offload requires an explicit scope.
