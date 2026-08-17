---
description: Task list for qwen38-27b-dual-5090-deployment phase 2.
---

# Tasks: qwen38-27b-dual-5090-deployment Phase 2

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

## Phase 2: Upstream CUDA Build
Goal: Build the pinned upstream runtime for Blackwell and prove it sees both GPUs.

Definition of Done: `llama-server` and `llama-bench` are built in Release mode with `120a`; the server prints a version and CUDA0/CUDA1 devices.

Tasks:
- [x] T021 [Infra] Configure and build Release CUDA targets
  - DoD: `JOBS=18 scripts/build-llama.sh` succeeds with CUDA `13.3.73`, `CMAKE_CUDA_ARCHITECTURES=120a`, and creates both binaries.
- [x] T022 [QA] Verify the built runtime devices
  - DoD: `llama-server --version` reports `34af94cd9` and `--list-devices` shows CUDA0/CUDA1 RTX 5090.
- [x] T023 [Security] Re-run host gate after build
  - DoD: `scripts/preflight.sh` passes after CUDA compilation.

Checkpoint: No model load begins until the built binary and two-device output pass.

## Dependencies & Execution Order
- Phase 1 blocks all others.
- Phase 2 depends on completion of phases 1-1.
- Tasks marked [P] within this phase may run concurrently only when they do not touch the same files.
