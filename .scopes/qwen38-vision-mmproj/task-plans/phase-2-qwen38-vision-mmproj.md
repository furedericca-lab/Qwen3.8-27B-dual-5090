---
description: Validate the explicitly approved 2048 MiB per-GPU fit target.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- `scripts/candidate-server.sh`
- `scripts/run-mtp-candidate.sh`
- accepted MTP and 256K settings in `AGENTS.md`

## Canonical Architecture / Key Constraints

- Only `--fit-target` changes from the prior production baseline.
- Keep upstream template, no mmproj, F16 KV, `-b 1024`, `-ub 256`, layer split,
  and MTP n-max 3.

## Phase 2: Fit Baseline

Goal: prove `2048,2048` is a viable new baseline before adding vision.
Definition of Done: startup and text/MTP evidence pass with both GPUs resident
and no CPU weight/KV offload.

Tasks:

- [x] T007 [Backend] Run fit-target-only candidate.
  - DoD: `PROFILE=baseline PORT=8001 scripts/run-mtp-candidate.sh fit-target 2048,2048` starts and records both free VRAM values.
- [x] T008 [QA] Validate text and MTP at the new target.
  - DoD: basic Responses and `benchmark-server-mtp.py` pass with positive drafted and accepted metrics.
- [x] T009 [Security] Inspect residency and host state.
  - DoD: startup log has no CPU model/KV offload, no CUDA OOM/Xid/BAD_PAGE, and post-run preflight passes.

Checkpoint: mmproj testing starts only after T007-T009 pass.

## Dependencies & Execution Order

Phase 0 blocks this phase. T007 precedes T008-T009.
