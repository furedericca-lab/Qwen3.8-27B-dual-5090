---
description: Scope milestones for qwen38-runtime-tuning.
---

# qwen38-runtime-tuning Scope Milestones

## In-scope

- Freeze and verify local SHA256; pin HF repo/revision/LFS SHA/size.
- Record dual-5090 PCIe/P2P topology.
- Candidate MTP sweeps: p-min then ubatch. One variable per comparison.
- Wiki/README/AGENTS updates that describe provenance and the still-frozen production baseline.

## Out-of-scope

- Changing `PROFILE=agent` defaults in `scripts/llama-server.sh`.
- `--spec-draft-n-max 3`, tensor/row split, draft models, ngram speculation.
- vLLM, requantize, CPU offload, wider bind than `127.0.0.1`.
- Hashing 29 GB inside `scripts/preflight.sh`.
- 20-50 turn soak of candidates (required only if a later scope promotes a candidate).

## Decision Log

- Production stays frozen: accepted baseline in `.wiki/decisions/deployment-baseline.md`.
- Layer split remains the production split mode: pipelined, not 2x TG.
- n-max stays 2 for all candidate runs in this scope.

## Milestones

| Milestone | Gate |
| --- | --- |
| M1 Provenance and topology | inspect-model verifies frozen SHA; HF pin matches remote; topology captured |
| M2 p-min sweep | four candidate MTP server benches at n-max=2 |
| M3 ubatch at best p-min | 256 vs 512, one variable |
| M4 Document and stop | results recorded; production unchanged unless a measured win is explicitly promoted later |

## Dependencies

M1 blocks M2. M2 selects the p-min used by M3. M4 depends on M1-M3 evidence.

## Exit criteria

- Tracked identity files are verify-only.
- Topology interpretation is in wiki.
- Candidate evidence exists under `evidence/` (gitignored run dirs).
- Production launcher diff is empty, or a follow-up production-change scope is named.

## Escalation triggers

- Remote LFS SHA != local frozen SHA.
- Host integrity gate fails before a candidate run.
- Candidate server CUDA lockup, Xid, or non-OOM crash.
- A candidate appears faster but breaks tool-call soak; do not promote.
