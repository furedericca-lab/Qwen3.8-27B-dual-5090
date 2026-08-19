---
description: Phase 4 records results, keeps production frozen, and stops.
---

# Tasks: qwen38-runtime-tuning

## Input

- Phase 1-3 evidence
- `.wiki/decisions/deployment-baseline.md`

## Canonical architecture / Key constraints

- n-max=3 and tensor split remain out of scope.
- Do not promote a candidate without soak; this phase only documents.

## Phase 4: Document and stop

Goal: Align wiki/README with provenance, topology, and candidate findings. Leave production defaults unchanged.

Definition of Done: wiki rebuilt, scope checklist updated, production launcher diff empty.

Tasks:

- [x] T012 [Docs] Write candidate findings into wiki and README without claiming unaudited speedups
  - DoD: every tok/s or acceptance figure cites an `evidence/` run.
- [x] T013 [Docs] Wiki rebuild/doctor after identity and topology pages
  - DoD: `ok-skill wiki-note rebuild` and `doctor --stale-refs` pass.
- [x] T014 [QA] Confirm stop conditions
  - DoD: no n-max or `-sm tensor` change; `git diff -- scripts/llama-server.sh` empty.

Checkpoint: Passed. Production unchanged. Scope may archive when requested.

## Dependencies & Execution Order

- Phase 4 depends on Phases 1-3.
