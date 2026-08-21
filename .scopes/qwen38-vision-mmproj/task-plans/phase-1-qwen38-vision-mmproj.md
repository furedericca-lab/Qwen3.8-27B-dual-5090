---
description: Compare and independently validate the pinned HF chat template.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- `scripts/candidate-server.sh`
- `scripts/run-mtp-candidate.sh`
- model `chat_template.jinja`
- `llama.cpp/models/templates/Qwen3.5-4B.jinja`

## Canonical Architecture / Key Constraints

- Template validation changes no model, mmproj, context, KV, ubatch, or MTP depth.
- Candidate fit baseline is `2048,2048`.
- Candidate bind is localhost and formal service must be stopped.

## Format

- `[ID] [Component] Description`
- Every task has a concrete DoD.

## Phase 1: Template

Goal: determine whether the pinned HF template can replace the upstream path.
Definition of Done: comparison evidence is retained; if non-identical, the HF
template candidate passes basic Responses, tool-call soak, and MTP text checks.

Tasks:

- [x] T004 [QA] Compare template bytes.
  - DoD: retain size, SHA256, `cmp`, and `diff -u` output under scope evidence.
- [x] T005 [Backend] Run `template hf` candidate.
  - DoD: `PROFILE=baseline PORT=8001 scripts/run-mtp-candidate.sh template hf` passes with fit target 2048.
- [x] T006 [QA] Inspect template candidate behavior.
  - DoD: basic Responses, 20-turn tool soak, and MTP drafted/accepted metrics all pass; otherwise template remains unpromoted.

Checkpoint: Phase 3 may use `TEMPLATE=hf` only if T005 and T006 pass.

## Dependencies & Execution Order

Phase 0 blocks this phase. T004 precedes T005-T006.
