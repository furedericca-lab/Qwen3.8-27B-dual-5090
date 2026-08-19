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
last_checked: 2026-08-19
updated: 2026-08-19T13:06:00Z
---

# VRAM Budget

No Qwen3.6 memory numbers are reused here. The accepted two-GPU fitting target is 4096 MiB on each RTX 5090. The MTP 128K F16-KV server used 18,413 MiB on GPU0 and 19,633 MiB on GPU1 after the 128K retrieval. The isolated target-model PP/TG benchmark retained in `evidence/benchmark-20260819T130345Z/` used the same two-GPU layer layout. MTP adds the embedded NextN head but does not change the fixed fit margin.

```text
min(GPU0 free, GPU1 free)
```

Use the minimum of the two cards, not aggregate free VRAM. The order for capacity pressure is smaller ubatch, larger fit target, KV type, then lower context. CPU offload requires an explicit scope.
