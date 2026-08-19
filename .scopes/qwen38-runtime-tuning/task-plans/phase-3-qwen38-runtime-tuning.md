---
description: Phase 3 compares ubatch 256 vs 512 at the best p-min.
---

# Tasks: qwen38-runtime-tuning

## Input

- Phase 2 winner p-min
- `scripts/candidate-server.sh`

## Canonical architecture / Key constraints

- One variable: ubatch. p-min stays at the Phase 2 winner. n-max stays 2.
- TG is not expected to jump; PP/agent prefill is the interesting signal.

## Phase 3: ubatch at best p-min

Goal: Compare `-ub 256` and `-ub 512` on the MTP server.

Definition of Done: two candidate benches, comparison recorded, production still frozen.

Tasks:

- [x] T010 [QA] Run ubatch 256 and 512 at the winning p-min
  - DoD: each run has preflight PASS and MTP summary; only ubatch differs.
- [x] T011 [Docs] Record PP/TG impact and whether a fit-target follow-up is warranted
  - DoD: checklist states keep 256, adopt 512 in a later production scope, or skip fit-target.

Checkpoint: Passed. Keep `-ub 256`. Skip fit-target. No n=3 or tensor split.

## Dependencies & Execution Order

- Phase 3 depends on Phase 2.
