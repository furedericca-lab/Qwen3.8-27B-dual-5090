---
description: Promote only the fully validated multimodal runtime to production.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- All Phase 0-5 evidence
- `scripts/llama-server.sh`
- `systemd/qwen38-27b.service`

## Canonical Architecture / Key Constraints

- The tracked systemd unit is unchanged; it supplies the existing LAN host.
- Production must use absolute model, mmproj, and pinned HF template paths.
- No automatic commit or push is part of this scope.

## Phase 6: Production Promotion

Goal: make the production launcher match the accepted combined candidate.
Definition of Done: production startup and API smoke use fit target 2048,
projector, accepted template, 256K, F16 KV, ubatch 256, and MTP n-max 3.

Tasks:

- [x] T018 [Backend] Promote accepted auxiliary paths.
  - DoD: `scripts/llama-server.sh` passes `--mmproj` and the accepted template path without changing frozen flags.
- [x] T019 [QA] Start and smoke the formal service.
  - DoD: service command line is correct, `172.30.0.214:8000` health/models/basic text pass, and GPU startup free VRAM is recorded.
- [x] T020 [Docs] Close the scope and report recommendation.
  - DoD: AGENTS, README, wiki references, checklist, and scope evidence agree; `bash -n`, Python compilation, and diff checks pass.

Checkpoint: report template identity, startup VRAM, vision result, MTP
sequence metrics, 256K result, and promotion recommendation before any commit.

## Dependencies & Execution Order

Phases 0-5 block this phase. T018 precedes T019-T020.
