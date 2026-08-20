---
description: Execution checklist for qwen38-runtime-tuning.
---

# Phases Checklist: qwen38-runtime-tuning

Input: `README.md`, `AGENTS.md`, `scripts/llama-server.sh`, `scripts/inspect-model.sh`, `.wiki/reference/model-metadata.md`, phase files under `task-plans/`.

| Phase | State | Completion | Health | Blockers |
| --- | --- | ---: | --- | --- |
| 1 Provenance and topology | Complete | 100% | healthy | none |
| 2 p-min sweep | Complete | 100% | healthy | none |
| 3 ubatch at best p-min | Complete | 100% | healthy | none |
| 4 Document and stop | Complete | 100% | healthy | none |

## Phase 1

- [x] T001-T006
- Evidence commands: `bash -n` PASS; `scripts/inspect-hf-source.sh` PASS (revision `2aff31a04896ab1f3716dde35f73d099ed0c08c5`, SHA `5d33641d...`); `scripts/inspect-model.sh` PASS and `evidence/model.sha256` unchanged; `scripts/inspect-topology.sh` PASS (PHB, P2P GNS, gen5/x16 caps, load width x8); `scripts/preflight.sh` PASS.
- Issues: none
- Checkpoint: passed

## Phase 2

- [x] T007-T009
- Evidence commands: `scripts/run-mtp-candidate.sh p-min {0,0.60,0.70,0.75}` all PASS. Winner: p-min 0 at 90.99/97.48/96.83 tok/s, 67.24% accept (`evidence/candidate-p-min-0-20260819T134027Z`). Higher p-min slower.
- Issues: none
- Checkpoint: passed; Phase 3 uses p-min 0

## Phase 3

- [x] T010-T011
- Evidence commands: `scripts/run-mtp-candidate.sh ubatch {256,512}` PASS. TG within noise; keep 256. Skip fit-target.
- Issues: none
- Checkpoint: passed

## Phase 4

- [x] T012-T014
- Evidence commands: wiki pages updated; `git diff -- scripts/llama-server.sh` empty; no n-max or tensor-split change.
- Issues: none
- Checkpoint: passed

## Recalibration 2026-08-20

- `scripts/inspect-model.sh` PASS; `evidence/model.sha256` unchanged.
- `scripts/inspect-hf-source.sh` FAIL: `hf_head_status=file-drift` (HEAD `1962512c` SHA `ea310156...`, size `29047084256`). Pinned revision still matches local.
- Production launcher remains n-max 3 from `e6bf41c`; this scope does not revert it.
- Do not download or promote HEAD. Archive this scope only on request.

## Final release gate

Original four phases complete at `922171d`. Later n-max=3 promotion is `e6bf41c`. Identity remains verify-only. Residual: HF HEAD filename drift fails the inspect gate until a new identity scope.
