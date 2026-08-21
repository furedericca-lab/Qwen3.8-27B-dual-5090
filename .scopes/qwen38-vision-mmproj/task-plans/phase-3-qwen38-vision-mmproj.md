---
description: Load the pinned mmproj on the 32K candidate and run vision smoke.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- `scripts/run-vision-candidate.sh`
- `scripts/probe-vision.py`
- pinned mmproj in the model directory

## Canonical Architecture / Key Constraints

- `mmproj on` adds only `--mmproj` to the upstream-template candidate.
- Projector GPU offload remains default; do not add `--no-mmproj-offload`.
- Use port 8001 and stop the formal systemd server first.

## Phase 3: mmproj 32K

Goal: prove the projector loads and the Responses vision path works.
Definition of Done: startup, health, model capability, deterministic image
recognition, and host-integrity evidence pass.

Tasks:

- [x] T010 [Infra] Stop the formal service before loading the candidate.
  - DoD: `qwen38-27b.service` is inactive, no llama-server owns port 8000, and the candidate owns only 127.0.0.1:8001.
- [x] T011 [Backend] Start the mmproj candidate.
  - DoD: `PROFILE=baseline PORT=8001 scripts/run-vision-candidate.sh mmproj on` records projector load, CUDA0/CUDA1, and 2048 fit target.
- [x] T012 [QA] Run deterministic vision smoke.
  - DoD: generated PNG and complete requests/responses are retained; JSON returns left red and right blue with no special-token leakage.

Checkpoint: Phase 4 requires T011-T012 and a clean post-run preflight.

## Dependencies & Execution Order

Phases 0-2 block this phase. T010 precedes T011; T011 precedes T012.
