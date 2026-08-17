---
description: Execution and verification checklist for qwen38-27b-dual-5090-deployment 5-phase plan.
---

# Phases Checklist: qwen38-27b-dual-5090-deployment

## Input
- Canonical docs under:
  - `.scopes/qwen38-27b-dual-5090-deployment`
  - `.scopes/qwen38-27b-dual-5090-deployment/task-plans`

## Rules
- Use this file as the single progress and audit hub.
- Update status, evidence commands, and blockers after each implementation batch.
- Do not mark a phase complete without evidence.

## Global Status Board
| Phase | Status | Completion | Health | Blockers |
|---|---|---|---|---|
| Phase 1 | Complete | 100% | Pass | 0 |
| Phase 2 | Complete | 100% | Pass | 0 |
| Phase 3 | In progress | 0% | Not run | 0 |
| Phase 4 | Not started | 0% | Not run | 1: Phase 3 |
| Phase 5 | Not started | 0% | Not run | 1: Phase 4 |

## Phase Entry Links
1. [phase-1-qwen38-27b-dual-5090-deployment.md](phase-1-qwen38-27b-dual-5090-deployment.md)
2. [phase-2-qwen38-27b-dual-5090-deployment.md](phase-2-qwen38-27b-dual-5090-deployment.md)
3. [phase-3-qwen38-27b-dual-5090-deployment.md](phase-3-qwen38-27b-dual-5090-deployment.md)
4. [phase-4-qwen38-27b-dual-5090-deployment.md](phase-4-qwen38-27b-dual-5090-deployment.md)
5. [phase-5-qwen38-27b-dual-5090-deployment.md](phase-5-qwen38-27b-dual-5090-deployment.md)

## Phase Execution Records

### Phase 1 - 2026-08-17

- Completed tasks: repository initialized; `origin` configured without pushing; official submodule pinned; model SHA256/metadata recorded; model mode changed to `0444`; deployment scripts, wiki, and scope docs created.
- Evidence commands: `scripts/inspect-model.sh`, `scripts/preflight.sh`, `bash -n scripts/*.sh`, `python3 -m py_compile scripts/*.py`, `git diff --check`.
- Result: pass. Preflight recorded ext4, taint `4096`, driver `610.43.02`, two RTX 5090 GPUs, and no matching integrity event.
- Issues/blockers: none.
- Checkpoint confirmed: yes.

### Phase 2 - 2026-08-17

- Completed tasks: CMake configuration and CUDA build; `llama-server` and `llama-bench` built.
- Evidence command: `JOBS=18 scripts/build-llama.sh`.
- Result: pass. `llama-server --version` reports build 10470 / `34af94cd9`; `--list-devices` reports CUDA0 and CUDA1 RTX 5090.
- Issues/blockers: none.
- Checkpoint confirmed: yes.

### Upstream refresh check - 2026-08-17

- Evidence commands: `git -C llama.cpp fetch origin`, `git -C llama.cpp rev-list --left-right --count HEAD...origin/master`, `git -C llama.cpp merge --ff-only origin/master`.
- Result: pass. Local and remote official `master` are both `34af94cd9ab277632e27caeec2d41de2fd091b31`; no rebuild is required because no code changed.

## Final Release Gate
- [x] Scope constraints and model identity are preserved.
- [x] Upstream CUDA build and two-device verification pass.
- [ ] 32K basic behavior probe passes.
- [ ] 128K F16 KV long-context baseline passes.
- [ ] 20-50 turn tool-call soak passes.
- [ ] No host-integrity event occurs during formal acceptance.
