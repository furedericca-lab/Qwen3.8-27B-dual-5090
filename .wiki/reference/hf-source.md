---
title: Hugging Face Source Pin
type: reference
status: current
scope: qwen38-multilingual-mtp-identity
related_scopes:
  - qwen38-runtime-tuning
  - qwen38-27b-dual-5090-deployment
related_files:
  - scripts/inspect-hf-source.sh
  - evidence/hf-source.txt
  - evidence/model.sha256
source_docs:
  - AGENTS.md
tags:
  - provenance
  - huggingface
last_checked: 2026-08-20
updated: 2026-08-20T14:45:00Z
---

# Hugging Face Source Pin

The production GGUF is the Hugging Face LFS object `RVN-Q8_0-multilingual-mtp.gguf` from `0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF`. Identity is the file SHA, not whatever happens to be HEAD later.

Pinned values live in `evidence/hf-source.txt`:

- revision `1962512c7354d17e1cb761e3848d6c2226d176ad`
- LFS SHA256 `3979ca0b400a091f60108906bd6a22907595e0dead3633bbda29b3400516f7bf`
- size `29047084512` bytes

Pinned auxiliary files in the same model directory (added 2026-08-21, verified against the pinned revision):

- `mmproj-Qwen3.8-27B-Q8_0.gguf` SHA256 `2e968a6af97ce35d8971890b257b9b7edabf20ad91450501fa53162a19ee33eb`, size `629247008` (LFS; remote etag is the SHA256).
- `chat_template.jinja` SHA256 `c3cf9e34abf4f9e36c2d72165aa9c132d3e2a725b6c2586aaa3a8af9d7a81041`, size `8952` (non-LFS; remote etag is a content md5, frozen as `hf_chat_template_pinned_remote_etag`). Both are mode `0444`.

`scripts/inspect-hf-source.sh` HEAD-requests the pinned revision and current HEAD resolve URLs for the GGUF and both auxiliary files and compares `x-linked-etag` plus `x-linked-size` with that pin and with `evidence/model.sha256`. It also hashes the small local auxiliary files and enforces mode `0444`. It must not rewrite the pin and must not hash 29 GB. A HEAD revision change with the same LFS SHA is a warning; a SHA or size mismatch is a failure. Do not auto-promote HEAD.

Retired artifact still on disk: `RVN-Q8_0-mtp.gguf` at SHA `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748`. It is not the production path.

Use this gate for model inspection and release, not inside `scripts/preflight.sh`.
