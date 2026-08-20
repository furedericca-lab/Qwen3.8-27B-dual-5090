---
description: Implementation research notes for qwen38-runtime-tuning.
---

# qwen38-runtime-tuning Implementation Research Notes

## Problem statement and current baseline

Production artifact: `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf` (29,047,075,232 bytes, SHA256 `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748`, mode 0444).

Canonical launcher: `scripts/llama-server.sh` (`PROFILE=agent`): 128K, F16 KV, `-b 1024 -ub 256`, `--fit-target 4096,4096`, layer split, `--spec-type draft-mtp --spec-draft-n-max 2`. `--spec-draft-p-min` is omitted and therefore llama.cpp default `0.00`.

`scripts/inspect-model.sh` currently recomputes SHA256 and overwrites `evidence/model.sha256`. `scripts/preflight.sh` checks ext4, mode 0444, and host integrity, not the frozen hash. No tracked HF revision or remote SHA exists. No PCIe/P2P evidence exists.

Accepted MTP server evidence remains `082e391`: target-only TG128 52.68 tok/s; MTP server ~91.95-98.41 tok/s; 67.14% acceptance.

## Gap analysis

- Local GGUF structure and SHA are recorded, but HF `x-linked-etag` / LFS oid and repo revision were not retained.
- Inspect is not a gate: a replaced 29 GB file would become the new expected hash.
- Dual-GPU decode uses layer split (pipelined). GeForce 5090 P2P reports `GNS`. Topology is needed before attributing any remaining TG gap to PCIe.
- No one-variable MTP p-min or MTP-model ubatch comparison exists. Earlier ubatch 512 evidence used the non-MTP `RVN-Q8_0.gguf`.

## Architecture/implementation options and trade-offs

- Verify-only inspect vs write-on-inspect: verify-only preserves identity; 29 GB hash stays on inspect/release, not preflight.
- Pin HF file SHA plus the revision that served it: HEAD may move when other quants are added; file SHA is the identity gate, pinned revision is the provenance snapshot.
- Candidate launcher vs mutating production: a separate `scripts/candidate-server.sh` keeps `scripts/llama-server.sh` byte-stable.
- p-min first vs n-max=3: n-max=2 is the author Q8_0 benchmark depth; p-min can stop low-confidence drafts without changing depth.

## Decision Roundtable

| Decision | Requirement Clarity | Evidence Strength | Evidence Source | Conflict | User-Intent Confidence | Implementation Confidence | Risk/Reversibility | Confidence Reason | Outcome |
| --- | ---: | ---: | --- | --- | ---: | ---: | ---: | --- | --- |
| Verify frozen SHA; do not overwrite | 5 | 5 | `scripts/inspect-model.sh`, `evidence/model.sha256` | none | 5 | 5 | 5 | overwrite bug is in source | verify-only inspect |
| Pin HF repo, revision, LFS SHA, size | 5 | 5 | HF API + resolve headers, local size/SHA | none | 5 | 5 | 5 | live remote SHA already matches local | tracked `evidence/hf-source.txt` |
| Record topology; keep layer split | 5 | 5 | `nvidia-smi topo`, PCI caps, llama.cpp `--split-mode` help | none | 5 | 5 | 5 | PHB + P2P GNS observed on this host | topology evidence + wiki |
| Sweep p-min at n-max=2 | 5 | 4 | user plan, llama.cpp `--spec-draft-p-min`, author n-max=2 | none | 5 | 4 | 4 | candidate-only; production frozen | p-min 0/0.60/0.70/0.75 |
| Defer n=3 and tensor split | 5 | 4 | llama.cpp experimental tensor split; user stop rule | none | 5 | 5 | 5 | stability baseline already accepted | out of scope |

## Selected design

1. `scripts/inspect-model.sh` runs `sha256sum -c evidence/model.sha256`.
2. `scripts/inspect-hf-source.sh` compares live HF headers and pinned revision against `evidence/hf-source.txt` and the frozen local SHA. It does not rewrite the pin and does not hash 29 GB.
3. `scripts/inspect-topology.sh` records PCIe caps, current idle link, topo matrix, and P2P status.
4. `scripts/candidate-server.sh` and `scripts/run-mtp-candidate.sh` change one variable per run.
5. Production `scripts/llama-server.sh` stays unchanged in this scope unless a later production-change scope is opened.

## Test and validation strategy

- `bash -n` on touched shell scripts; `python3 -m py_compile` on touched Python; `git diff --check`.
- `scripts/inspect-hf-source.sh` must PASS against pinned SHA `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748` and size `29047075232`.
- `scripts/inspect-model.sh` must PASS `sha256sum -c` without modifying `evidence/model.sha256`.
- Topology script must report both GPUs, PHB, P2P `GNS`, and PCIe gen5/x16 caps.
- Each MTP candidate: `scripts/preflight.sh`, `/health`, `python3 scripts/benchmark-server-mtp.py`. Record drafted/accepted metrics. Do not claim a production default change.

## Risks, assumptions, unresolved questions

- Idle PCIe current gen1/x8 is ASPM/power-management downclock; caps are gen5/x16. Load-time link state is recorded with candidate GPU snapshots, not treated as a wiring fault from idle dumps alone.
- HF HEAD may move while the Q8_0 MTP LFS oid stays the same; file SHA mismatch is FAIL, revision drift with matching SHA is recorded, not auto-promoted.
- Recalibrated 2026-08-20: HEAD `1962512c` replaced `RVN-Q8_0-mtp.gguf` (size +9024 bytes, new LFS SHA `ea310156...`). Pinned revision `2aff31a0` still matches local. Treat as identity drift, not a silent upgrade.
- p-min may raise tok/s while lowering acceptance; promotion needs both throughput and soak, which this scope does not perform.
