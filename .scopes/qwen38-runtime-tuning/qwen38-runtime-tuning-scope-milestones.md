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

- Original production freeze held through `922171d` (p-min/ubatch candidates did not beat n-max=2).
- Later measured n-max=3,p-min=0 win was promoted in `e6bf41c`; layer split remains production split mode.
- This scope must not auto-promote the 2026-08-20 HF HEAD `RVN-Q8_0-mtp.gguf` replacement.

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
- Original launcher freeze recorded at `922171d`; follow-up production-change for n-max=3 is `e6bf41c`.
- HF pin remains verify-only against revision `2aff31a0`; HEAD file drift stays FAIL.

## Escalation triggers

- Pinned-revision remote LFS SHA != local frozen SHA.
- HEAD filename SHA drift without an identity-promotion scope.
- Host integrity gate fails before a candidate run.
- Candidate server CUDA lockup, Xid, or non-OOM crash.
- A candidate appears faster but breaks tool-call soak; do not promote.
