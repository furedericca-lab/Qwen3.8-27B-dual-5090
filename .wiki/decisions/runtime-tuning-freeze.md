---
title: Runtime Tuning Freeze
type: decision
status: accepted
scope: qwen38-runtime-tuning
related_scopes:
  - qwen38-27b-dual-5090-deployment
related_files:
  - scripts/llama-server.sh
  - scripts/candidate-server.sh
source_docs:
  - .scopes/qwen38-runtime-tuning/qwen38-runtime-tuning-implementation-research-notes.md
tags:
  - tuning
  - p-min
last_checked: 2026-08-19
updated: 2026-08-19T13:36:51Z
decision_date: 2026-08-19
---

# Runtime Tuning Freeze

Keep `scripts/llama-server.sh` at the accepted 128K MTP agent profile. Candidate evidence from `.scopes/qwen38-runtime-tuning` did not beat that default on throughput.

Measured 2026-08-19: `--spec-draft-p-min 0` remains fastest (~91/97/97 tok/s short/medium/long, 67.2% accept). Raising p-min to 0.60-0.75 increased acceptance (83-91%) and lowered tok/s; higher p-min also changed long-run completion length. `-ub 512` matched `-ub 256` on this decode-heavy MTP harness. n-max=3, tensor split, and fit-target were not run.

Rejected: overwriting `evidence/model.sha256` on inspect; hashing 29 GB in preflight; promoting a slower p-min or an unmeasured PP-only ubatch change.
