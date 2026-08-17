---
description: Task list for qwen38-27b-dual-5090-deployment phase 5.
---

# Tasks: qwen38-27b-dual-5090-deployment Phase 5

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

## Phase 5: Agent Acceptance
Goal: Prove multi-turn local tool-call continuity before declaring the agent profile ready.

Definition of Done: A 20-50 turn soak passes with exactly one valid tool call per turn, valid arguments, retained responses, and a post-run clean host gate.

Tasks:
- [ ] T081 [Agentic] Run deterministic tool-call soak
  - DoD: `python3 scripts/soak-agent.py --turns 20` retains all responses with one `lookup` call and the expected integer argument per turn.
- [ ] T082 [QA] Review agent response failure modes
  - DoD: Evidence confirms no empty response, malformed arguments, duplicate tool call, special token leakage, or runaway output in the accepted run.
- [ ] T083 [Security] Confirm post-soak integrity
  - DoD: `scripts/preflight.sh` passes after the soak and the active checklist records final evidence paths and residual risk.

Checkpoint: Only a completed Phase 5 may propose an `agent` production profile.

## Dependencies & Execution Order
- Phase 1 blocks all others.
- Phase 5 depends on completion of phases 1-4.
- Tasks marked [P] within this phase may run concurrently only when they do not touch the same files.
