---
title: Production Model Metadata
type: reference
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/inspect-model.sh, evidence/model.sha256]
code_anchors: []
source_docs: [AGENTS.md]
tags: [model, gguf, q8-0, mtp]
last_checked: 2026-08-19
updated: 2026-08-19T13:06:00Z
---

# Production Model Metadata

Recorded on 2026-08-19 from the fixed artifact:

```text
Path: /data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf
Size: 29,047,075,232 bytes
SHA256: 5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748
Mode: 0444
Architecture: qwen35
Name: Qwen38 Ara v5
Size label: 27B
GGUF file type: 7 (Q8_0)
Quantization version: 2
Blocks: 65
Native context: 262144
Embedding length: 5120
Attention heads: 24
KV heads: 4
Key/value length: 256 / 256
Full-attention interval: 4
NextN predict layers: 1
Tensor count: 866
NextN/MTP tensors: 4
NextN tensors: blk.64.nextn.eh_proj.weight [10240, 5120] Q8_0; blk.64.nextn.shared_head_norm.weight; blk.64.nextn.enorm.weight; blk.64.nextn.hnorm.weight
```

The GGUF has no embedded chat template, so the canonical launcher supplies upstream `models/templates/Qwen3.5-4B.jinja`. The NextN tensors initialized `draft-mtp` successfully at 128K with draft depth 2; the 20-turn tool-call soak passed with `enable_thinking=false` for deterministic response content.
