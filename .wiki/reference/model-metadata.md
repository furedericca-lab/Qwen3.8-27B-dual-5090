---
title: Production Model Metadata
type: reference
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/inspect-model.sh, evidence/model.sha256]
code_anchors: []
source_docs: [AGENTS.md]
tags: [model, gguf, q8-0]
last_checked: 2026-08-17
updated: 2026-08-17T15:15:00Z
---

# Production Model Metadata

Recorded on 2026-08-17 from the fixed artifact:

```text
Path: /data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0.gguf
Size: 28,595,754,496 bytes
SHA256: 638be14a0062789de1bcc714dc04c3d108ff9c3db054a74aaf2f25cca321d7ca
Architecture: qwen35
Name: Qwen38 Ara v5
Size label: 27B
GGUF file type: 7 (Q8_0)
Quantization version: 2
Blocks: 64
Native context: 262144
Embedding length: 5120
Attention heads: 24
KV heads: 4
Key/value length: 256 / 256
Full-attention interval: 4
Tensor count: 851
MTP tensors: 0
```

No `nextn_predict_layers` metadata, MTP tensors, or embedded chat template were present. The canonical launcher therefore supplies upstream `models/templates/Qwen3.5-4B.jinja`; a 128K A/B returned a valid required tool call with `{"turn":1}`.
