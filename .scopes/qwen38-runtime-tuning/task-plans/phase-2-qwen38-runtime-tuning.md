---
description: Phase 2 sweeps spec-draft-p-min at fixed n-max=2.
---

# Tasks: qwen38-runtime-tuning

## Input

- Frozen production command in `scripts/llama-server.sh`
- `scripts/benchmark-server-mtp.py`
- `scripts/preflight.sh`

## Canonical architecture / Key constraints

- n-max stays 2.
- Change only `--spec-draft-p-min`.
- Do not edit production defaults.

## Phase 2: p-min sweep

Goal: Measure MTP server throughput and acceptance at p-min 0, 0.60, 0.70, 0.75.

Definition of Done: four candidate evidence dirs with MTP drafted/accepted metrics and host preflight.

Tasks:

- [x] T007 [Backend] Add `scripts/candidate-server.sh` and `scripts/run-mtp-candidate.sh`
  - DoD: one changed variable per invocation; production launcher untouched.
- [x] T008 [QA] Run p-min 0 / 0.60 / 0.70 / 0.75 candidate benches
  - DoD: each run has preflight PASS, `/health`, and `benchmark-server-mtp.py` summary.
- [x] T009 [Docs] Record the best p-min in the checklist without promoting it
  - DoD: checklist names the winner and the measured tok/s / acceptance; `llama-server.sh` unchanged.

Checkpoint: Passed. Best p-min is 0. Phase 3 uses p-min 0.

## Dependencies & Execution Order

- Phase 2 depends on Phase 1.
- T008 depends on T007.
