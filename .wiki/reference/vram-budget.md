---
title: VRAM Budget
type: reference
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment, qwen38-vision-mmproj]
related_files: [scripts/llama-server.sh, scripts/candidate-server.sh, scripts/benchmark-runtime.sh]
code_anchors: []
source_docs: [.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-scope-milestones.md, .scopes/qwen38-vision-mmproj/qwen38-vision-mmproj-scope-milestones.md]
tags: [vram, fit-target, dual-5090]
last_checked: 2026-08-21
updated: 2026-08-21T00:00:00Z
---

# VRAM Budget

No Qwen3.6 memory numbers are reused here. The accepted current fitting target is 2048 MiB on each RTX 5090 with the pinned GPU-offloaded mmproj. The final 256K multimodal acceptance started at 23,679/24,781 MiB used, leaving 8,471/7,336 MiB free on GPU0/GPU1 (`evidence/acceptance-256k-mmproj-hf-20260821T131526Z/`); the long retrieval/benchmark minimum snapshot was 8,379/7,294 MiB free. The prior 4096 MiB run is historical evidence for the old target. The earlier 128K multilingual MTP load used about 18.5 / 19.7 GiB. The isolated target-model PP/TG benchmark retained in `evidence/benchmark-20260819T130345Z/` used the same two-GPU layer layout. MTP adds the embedded NextN head but does not change the requested fit margin.

```text
min(GPU0 free, GPU1 free)
```

Use the minimum of the two cards, not aggregate free VRAM. The order for capacity pressure is smaller ubatch, larger fit target, KV type, then lower context. CPU offload requires an explicit scope.
