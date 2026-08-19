---
description: Phase 1 locks HF provenance, verifies frozen SHA, and records topology.
---

# Tasks: qwen38-runtime-tuning

## Input

- `scripts/inspect-model.sh`
- `evidence/model.sha256`
- `scripts/preflight.sh`
- Hugging Face repo `0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF`

## Canonical architecture / Key constraints

- Do not overwrite `evidence/model.sha256`.
- Do not hash 29 GB in preflight.
- Do not change `scripts/llama-server.sh`.

## Format

- `[ID] [P?] [Component] Description`
- `[P]` means parallelizable.

## Phase 1: Provenance and topology

Goal: Close local/remote model identity and record dual-5090 PCIe/P2P facts.

Definition of Done: verify-only inspect, tracked HF pin, topology snapshot, wiki pages, `bash -n` pass.

Tasks:

- [x] T001 [Backend] Make `scripts/inspect-model.sh` verify `evidence/model.sha256`
  - DoD: script uses `sha256sum -c`; a successful run leaves `evidence/model.sha256` unchanged.
- [x] T002 [Backend] Add `scripts/inspect-hf-source.sh` and tracked `evidence/hf-source.txt`
  - DoD: live HF LFS SHA and size match the pin and `evidence/model.sha256`; script does not rewrite the pin.
- [x] T003 [P] [Infra] Add `scripts/inspect-topology.sh`
  - DoD: records topo matrix, P2P, and PCIe max/current for both 5090s.
- [x] T004 [Config] Whitelist `evidence/hf-source.txt` in `.gitignore`
  - DoD: `git check-ignore` does not ignore `evidence/hf-source.txt`.
- [x] T005 [Docs] Update README, AGENTS, evidence README, and wiki identity/topology pages
  - DoD: docs say inspect verifies and does not overwrite; HF pin and topology are linked.
- [x] T006 [QA] Run inspect and syntax checks
  - DoD: `bash -n` on new/changed scripts; `inspect-hf-source.sh` PASS; `inspect-model.sh` PASS.

Checkpoint: Passed. HF pin matches local SHA `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748`. Topology is PHB + P2P GNS, caps gen5 x16.

## Dependencies & Execution Order

- Phase 1 blocks all others.
- T001-T005 may overlap; T006 depends on T001-T004.
