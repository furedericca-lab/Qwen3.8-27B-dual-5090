---
description: Task list for qwen38-27b-dual-5090-deployment phase 4.
---

# Tasks: qwen38-27b-dual-5090-deployment Phase 4

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

## Phase 4: 128K Runtime Baseline
Goal: Measure the required F16 KV 128K candidate before promoting any profile.

Definition of Done: 128K startup, PP/TG benchmark output, GPU/RAM/power snapshots, long-context retrieval, and post-run host gate pass are retained.

Tasks:
- [x] T061 [Infra] Start the 128K candidate
  - DoD: `CONTEXT=131072 scripts/llama-server.sh` starts with F16 KV, no MTP, no CPU offload, and a clean preflight.
- [x] T062 [QA] Measure runtime and long context
  - DoD: `scripts/benchmark-runtime.sh` and `python3 scripts/probe-long-context.py --target-tokens 32768` retain measurements and retrieval output.
- [x] T063 [Security] Validate post-run host state
  - DoD: The post-run preflight passes and `min(GPU0 free, GPU1 free)` is recorded for comparison.

Checkpoint: Phase 5 begins only after a 128K baseline is accepted.

## Dependencies & Execution Order
- Phase 1 blocks all others.
- Phase 4 depends on completion of phases 1-3.
- Tasks marked [P] within this phase may run concurrently only when they do not touch the same files.
