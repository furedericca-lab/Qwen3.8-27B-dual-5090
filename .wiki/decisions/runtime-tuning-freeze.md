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
  - ubatch
last_checked: 2026-08-19
updated: 2026-08-19T13:36:51Z
decision_date: 2026-08-19
---

# Runtime Tuning Freeze

Keep `scripts/llama-server.sh` at the accepted 128K MTP agent profile. Candidate evidence from `.scopes/qwen38-runtime-tuning` did not beat that default on throughput.

Measured 2026-08-19: `--spec-draft-p-min 0` remains fastest (~91/97/97 tok/s short/medium/long, 67.2% accept). Raising p-min to 0.60-0.75 increased acceptance (83-91%) and lowered tok/s; higher p-min also changed long-run completion length.

The long-prompt sweep under `evidence/ubatch-long-prompt-20260819T142649Z/`
freezes `-b 1024 -ub 256`. Against ub=128, ub=256 improved PP by 37.25%,
26.47%, and 7.13% at 32K, 64K, and 128K envelopes. ub=512 was 1.42%,
1.75%, and 4.73% slower than ub=256 and consumed more VRAM. All nine runs
and the post-run host preflight passed. n-max=3, tensor split, and fit-target
remain unaccepted unless separately recorded below.

The n-max=3 sweep selected p-min 0 at 98.30/103.81/103.23 tok/s. This beats
the n-max=2,p-min=0 baseline by 8.03%/6.49%/6.61%, while preserving benchmark
completion lengths and finish reasons. Basic probes, a 130090-token retrieval,
a 20-turn tool-call soak, and the post-run host gate passed. Production now
uses `--spec-draft-n-max 3` and continues to omit `--spec-draft-p-min`.

Rejected: overwriting `evidence/model.sha256` on inspect; hashing 29 GB in preflight; promoting a slower p-min or an unmeasured PP-only ubatch change.
