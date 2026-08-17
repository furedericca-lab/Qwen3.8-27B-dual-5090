---
description: Task list for qwen38-27b-dual-5090-deployment phase 3.
---

# Tasks: qwen38-27b-dual-5090-deployment Phase 3

## Input
- Canonical sources:
  - `README.md`
  - `.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-scope-milestones.md`
  - `.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-brainstorming.md`
  - `.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-implementation-research-notes.md`
  - `.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-technical-documentation.md`
  - `.scopes/qwen38-27b-dual-5090-deployment/qwen38-27b-dual-5090-deployment-contracts.md`

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

## Phase 3: 32K Server Smoke
Goal: Prove the fixed model loads and behaves coherently with the canonical baseline launcher.

Definition of Done: A clean preflight, local server startup, health/models endpoints, basic Chinese/JSON/Python responses, and post-run resource/kernel snapshot are retained.

Tasks:
- [ ] T041 [Infra] Start the 32K canonical server
  - DoD: `scripts/llama-server.sh` starts on `127.0.0.1:8000` after `scripts/preflight.sh` passes.
- [ ] T042 [QA] Execute basic behavior probes
  - DoD: `scripts/probe-basic.sh` retains health, models, Chinese, JSON, and Python responses without empty/special-token output.
- [ ] T043 [Security] Confirm post-run host integrity
  - DoD: `scripts/preflight.sh` passes after shutdown; evidence includes GPU/RAM/swap state and exit status.

Checkpoint: Phase 4 must not claim 128K before this 32K smoke passes.

## Dependencies & Execution Order
- Phase 1 blocks all others.
- Phase 3 depends on completion of phases 1-2.
- Tasks marked [P] within this phase may run concurrently only when they do not touch the same files.
