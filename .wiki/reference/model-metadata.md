---
title: Production Model Metadata
type: reference
status: current
scope: qwen38-multilingual-mtp-identity
related_scopes: [qwen38-27b-dual-5090-deployment, qwen38-runtime-tuning]
related_files: [scripts/inspect-model.sh, scripts/inspect-hf-source.sh, evidence/model.sha256, evidence/hf-source.txt]
code_anchors: []
source_docs: [AGENTS.md]
tags: [model, gguf, q8-0, mtp, provenance]
last_checked: 2026-08-20
updated: 2026-08-20T14:45:00Z
---

# Production Model Metadata

Recorded on 2026-08-20 from the current production artifact:

```text
Path: /data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-multilingual-mtp.gguf
Size: 29,047,084,512 bytes
SHA256: 3979ca0b400a091f60108906bd6a22907595e0dead3633bbda29b3400516f7bf
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

Hugging Face pin in `evidence/hf-source.txt`:

```text
repo: 0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF
file: RVN-Q8_0-multilingual-mtp.gguf
revision: 1962512c7354d17e1cb761e3848d6c2226d176ad
LFS SHA256: 3979ca0b400a091f60108906bd6a22907595e0dead3633bbda29b3400516f7bf
size: 29047084512
```

`scripts/inspect-model.sh` verifies the frozen local SHA and does not overwrite it. `scripts/inspect-hf-source.sh` compares live resolve headers (`x-linked-etag`, `x-linked-size`) with that pin and does not hash 29 GB. Preflight still only checks ext4 and mode 0444.

This GGUF embeds `tokenizer.chat_template` (vision/tools-aware Qwen3.8 template). The canonical launcher still passes `--chat-template-file llama.cpp/models/templates/Qwen3.5-4B.jinja` so template behavior stays a separate variable from this identity switch. Multilingual-MTP acceptance on 2026-08-20: 130,090-token retrieval (`evidence/long-context-20260820T150628Z`), 20-turn tool soak (`evidence/agent-soak-20260820T150731Z`), MTP bench 98.27/103.62/102.98 tok/s at 55.42% accept (`evidence/mtp-server-benchmark-20260820T150745Z`).
