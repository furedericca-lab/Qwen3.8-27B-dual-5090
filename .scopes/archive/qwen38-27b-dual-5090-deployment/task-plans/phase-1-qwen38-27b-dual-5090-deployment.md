---
description: Task list for qwen38-27b-dual-5090-deployment phase 1.
---

# Tasks: qwen38-27b-dual-5090-deployment Phase 1

## Input
- Canonical sources:
  - `README.md`
  - `.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-scope-milestones.md`
  - `.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-brainstorming.md`
  - `.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-implementation-research-notes.md`
  - `.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-technical-documentation.md`
  - `.scopes/archive/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-contracts.md`

## Canonical architecture / Key constraints
- Keep architecture aligned with qwen38-27b-dual-5090-deployment scope docs and contracts.
- Preserve the decision chain from research notes, brainstorming decisions, and
  scope milestones.
- Keep provider/runtime/channel boundaries unchanged unless explicitly in scope.
- Keep security and test gates in Definition of Done.

## Format
- [ID] [P?] [Component] Description
- [P] means parallelizable.
- Valid components: Backend, Frontend, Agentic, Docs, Config, QA, Security, Infra.
- Every task must have a clear DoD.

## Phase 1: Repository and Model Identity
Goal: Establish one immutable model identity, a deployment-only repository, and an admissible host gate.

Definition of Done: The exact Q8_0 artifact, official upstream gitlink, scripts, documentation, and preflight evidence are recorded without loading the model.

Tasks:
- [x] T001 [Config] Initialize upstream deployment repository
  - DoD: `.gitmodules` pins official `llama.cpp`; `origin` points to the user-provided GitHub repository without pushing.
- [x] T002 [Security] Fix and record production model identity
  - DoD: `evidence/model.sha256` and `.wiki/reference/model-metadata.md` record exact path, SHA256, metadata, and `0444` mode.
- [x] T003 [QA] Add host and static gates
  - DoD: `scripts/preflight.sh`, `bash -n scripts/*.sh`, `python3 -m py_compile scripts/*.py`, and `git diff --check` pass.

Checkpoint: Phase 1 evidence is recorded in `5phases-checklist.md`; Phase 2 may build the pinned submodule.

## Dependencies & Execution Order
- Phase 1 blocks all others.
- This phase must complete before any later phase starts.
- Tasks marked [P] within this phase may run concurrently only when they do not touch the same files.
