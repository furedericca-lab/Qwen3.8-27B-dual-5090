---
description: Run the final combined 256K multimodal acceptance suite.
---

# Tasks: Qwen3.8 Vision mmproj

## Input

- Passed template, fit, mmproj, and MTP evidence
- `scripts/probe-long-context.py`
- `scripts/soak-agent.py`
- `scripts/benchmark-server-mtp.py`

## Canonical Architecture / Key Constraints

- Context is exactly 262144; do not reduce it to recover capacity.
- Combined candidate uses `TEMPLATE=hf`, mmproj on, fit target 2048, F16 KV,
  ubatch 256, layer split, and MTP n-max 3.

## Phase 5: 256K Acceptance

Goal: prove the final multimodal runtime retains production capacity and agent
behavior. Definition of Done: every required gate passes with retained output.

Tasks:

- [x] T015 [Backend] Start the combined 256K candidate.
  - DoD: `PROFILE=agent PORT=8001 TEMPLATE=hf scripts/run-vision-candidate.sh mmproj on` starts without OOM or CPU weight/KV offload.
- [x] T016 [QA] Run 256K workload suite.
  - DoD: preflight, basic, vision, 262144-token retrieval, MTP benchmark, and 20-turn soak all pass.
- [x] T017 [Security] Complete post-run host and resource checks.
  - DoD: post-run preflight passes and final GPU/RAM/swap snapshots are retained.

Checkpoint: Phase 6 promotion is prohibited until T015-T017 all pass.

## Dependencies & Execution Order

Phases 0-4 block this phase. T015 precedes T016; T017 follows shutdown.
