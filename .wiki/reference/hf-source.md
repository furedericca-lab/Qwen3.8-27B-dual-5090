---
title: Hugging Face Source Pin
type: reference
status: current
scope: qwen38-runtime-tuning
related_scopes:
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
last_checked: 2026-08-19
updated: 2026-08-19T13:36:51Z
---

# Hugging Face Source Pin

The production GGUF is the Hugging Face LFS object `RVN-Q8_0-mtp.gguf` from `0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF`. Identity is the file SHA, not whatever happens to be HEAD later.

Pinned values live in `evidence/hf-source.txt`:

- revision `2aff31a04896ab1f3716dde35f73d099ed0c08c5`
- LFS SHA256 `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748`
- size `29047075232` bytes

`scripts/inspect-hf-source.sh` HEAD-requests the pinned revision and current HEAD resolve URLs and compares `x-linked-etag` plus `x-linked-size` with that pin and with `evidence/model.sha256`. It must not rewrite the pin and must not hash 29 GB. A HEAD revision change with the same LFS SHA is a warning; a SHA or size mismatch is a failure.

Use this gate for model inspection and release, not inside `scripts/preflight.sh`.
