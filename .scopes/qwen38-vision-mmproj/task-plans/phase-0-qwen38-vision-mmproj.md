---
description: Verify and normalize frozen auxiliary artifact provenance.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- `evidence/hf-source.txt`
- `scripts/inspect-hf-source.sh`
- `AGENTS.md`

## Canonical Architecture / Key Constraints

- Pinned values are verify-only.
- The model directory is `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF`.
- The three local artifacts must remain mode `0444`.

## Format

- `[ID] [Component] Description`
- Every task has a concrete DoD.

## Phase 0: Provenance

Goal: remove duplicate keys and prove local/remote identity remains unchanged.
Definition of Done: the inspect gate passes and all three artifact modes are
0444 without a pin rewrite.

Tasks:

- [x] T001 [Security] Remove duplicate auxiliary ETag keys.
  - DoD: each `hf_*_pinned_remote_etag` key occurs once and no SHA/size/revision value changes.
- [x] T002 [QA] Run the HF source gate.
  - DoD: `scripts/inspect-hf-source.sh` exits 0 and reports auxiliary local SHA/size matches.
- [x] T003 [QA] Record artifact filesystem state.
  - DoD: `stat` records ext4 model mount, exact sizes, and mode `0444` for model, mmproj, and template.

Checkpoint: Phase 1 and Phase 2 may start only after T002 passes.

## Dependencies & Execution Order

T001 precedes T002. T003 may run with T002 but must be recorded before the
checkpoint.
