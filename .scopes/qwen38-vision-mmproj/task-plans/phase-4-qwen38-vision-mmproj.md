---
description: Verify text and MTP behavior around a multimodal turn.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- Phase 3 vision candidate evidence
- `/metrics` output
- `scripts/probe-vision.py`

## Canonical Architecture / Key Constraints

- Required request order is `text -> image -> text`.
- MTP remains draft-MTP n-max 3; no new MTP parameter is permitted.

## Phase 4: MTP Regression

Goal: prove vision does not crash, OOM, pollute the slot, or disable later MTP.
Definition of Done: post-sequence drafted and accepted counters advance and the
server log contains no integrity or allocation failure.

Tasks:

- [x] T013 [QA] Capture metrics before and after the sequence.
  - DoD: `mtp-sequence-summary.json` reports positive drafted and accepted deltas after the third text request.
- [x] T014 [QA] Inspect runtime residency and output quality.
  - DoD: text outputs remain non-empty, F16 KV and ubatch 256 are retained, and no CPU offload/OOM/Xid/BAD_PAGE appears.

Checkpoint: Phase 5 may start only after T013-T014 pass.

## Dependencies & Execution Order

Phase 3 blocks this phase. T013 and T014 use the same retained run directory.
