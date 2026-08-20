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

No Qwen3.6 memory numbers are reused here. The accepted two-GPU fitting target is 4096 MiB on each RTX 5090. The multilingual MTP 256K F16-KV server used 22,847 MiB on GPU0 and 24,823 MiB on GPU1 after the 256K suite (`evidence/candidate-context-262144-20260820T152513Z`), leaving 9,303 / 7,294 MiB free. The earlier 128K multilingual MTP load used about 18.5 / 19.7 GiB. The isolated target-model PP/TG benchmark retained in `evidence/benchmark-20260819T130345Z/` used the same two-GPU layer layout. MTP adds the embedded NextN head but does not change the fixed fit margin.

```text
min(GPU0 free, GPU1 free)
```

Use the minimum of the two cards, not aggregate free VRAM. The order for capacity pressure is smaller ubatch, larger fit target, KV type, then lower context. CPU offload requires an explicit scope.
