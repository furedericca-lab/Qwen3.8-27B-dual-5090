---
description: Verify downloaded RVN-Q8_0-multilingual-mtp.gguf against HF, lock mode 0444, and make it the production artifact.
---

# qwen38-multilingual-mtp-identity Contract

## Context

- Current repo/worktree: `/home/build/work/Qwen3.8-27B-dual-5090`
- Relevant source paths: `scripts/llama-server.sh`, `scripts/inspect-model.sh`, `scripts/inspect-hf-source.sh`, `evidence/model.sha256`, `evidence/hf-source.txt`
- Relevant archived scope references: `.scopes/qwen38-runtime-tuning` recorded the previous `RVN-Q8_0-mtp.gguf` pin and HEAD drift of that filename.

## Findings

- Local file `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-multilingual-mtp.gguf` size `29047084512`.
- Local SHA256 `3979ca0b400a091f60108906bd6a22907595e0dead3633bbda29b3400516f7bf`.
- HF resolve of revision `1962512c7354d17e1cb761e3848d6c2226d176ad` / `RVN-Q8_0-multilingual-mtp.gguf` returns `x-linked-etag` `3979ca0b...` and `x-linked-size` `29047084512`.
- GGUF metadata: qwen35, Q8_0, 65 blocks, one NextN layer, four `blk.64.nextn.*` tensors.
- After `sudo chmod 0444`, mode is `444`, owner `root:build`.

## Outcome

- Done when: pin files, launchers, inspect, and preflight all point at the multilingual MTP GGUF; inspect-hf-source PASSes; previous GGUF is not launched by production scripts.
- User-visible/runtime state: `PROFILE=agent scripts/llama-server.sh` loads `RVN-Q8_0-multilingual-mtp.gguf`.
- Durable knowledge to preserve: new SHA/size/revision; retired previous artifact path.

## Goals / Non-goals

Goals:
- Verify local download against live HF LFS identity.
- Lock mode 0444.
- Switch production identity and launchers to this file.

Non-goals:
- Deleting `RVN-Q8_0-mtp.gguf`.
- Requantizing or redownloading.
- Auto-promoting later HEAD replacements.
- Re-running the 2026-08-19 p-min/ubatch matrix on the old file.

## Target files / modules

- `evidence/model.sha256`
- `evidence/hf-source.txt`
- `scripts/inspect-model.sh`
- `scripts/llama-server.sh`
- `scripts/candidate-server.sh`
- `scripts/preflight.sh`
- `scripts/benchmark-runtime.sh`
- `scripts/run-ubatch-sweep.sh`
- `AGENTS.md`, `README.md`, `.wiki/reference/hf-source.md`, `.wiki/reference/model-metadata.md`

## Constraints

- Identity files are verify-only after this write.
- Bind remains `127.0.0.1`.
- Runtime knobs stay n-max 3, `-ub 256`, layer split.
- Do not hash 29 GB in preflight.

## Boundaries

Allowed changes:
- Production model path and frozen hash/pin.
- Inspect expected path (no `*Q8_0*` glob).

Forbidden changes:
- llama.cpp submodule edits.
- Wider bind, tensor split, CPU offload.
- Rewriting historical evidence dirs.

## Decision Summary

| Decision | Evidence Source | Evidence Strength | Conflict | Result | Confidence Reason |
| --- | --- | --- | --- | --- | --- |
| Promote multilingual MTP as production | user + HF headers + local sha256sum | 5 | none | switch pin and launchers | SHA and size match live resolve |
| Keep previous GGUF on disk | runtime | 5 | none | retired, not launched | user did not authorize deletion |
| Do not cite old soak/TG as new-model results | AGENTS.md | 5 | none | residual until re-run | different SHA |

## Verification surface

- `sha256sum` local == HF `x-linked-etag`
- `stat -c %s` == `29047084512` and mode `444`
- `scripts/inspect-model.sh` PASS without rewriting `evidence/model.sha256`
- `scripts/inspect-hf-source.sh` PASS
- `scripts/preflight.sh` PASS
- `bash -n` on touched shell scripts

## Escalation triggers

- Local SHA != remote LFS SHA.
- Missing NextN tensors.
- Host integrity gate fails before a new-model soak.

## Rollback

Point launchers and `evidence/model.sha256` back to `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf` SHA `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748` (file still present, mode 0444).

## Open questions

- None for identity. 128K retrieval, 20-turn soak, and MTP server bench on the new SHA remain required before citing production-readiness numbers.

## Execution log / evidence updates

- 2026-08-20: local SHA matched HF `x-linked-etag`; chmod 0444; pin and launchers switched.
- `scripts/inspect-model.sh` PASS, hash file unchanged. `scripts/inspect-hf-source.sh` PASS (`hf_head_status=match`). `scripts/preflight.sh` PASS.
- New GGUF embeds `tokenizer.chat_template`; launcher still supplies `Qwen3.5-4B.jinja` (not changed in this identity switch).
- 2026-08-20 server pid 5733: `probe-basic` PASS; 128K retrieval PASS (`evidence/long-context-20260820T150628Z`, prompt 130090); 20-turn soak PASS (`evidence/agent-soak-20260820T150731Z`); MTP bench PASS (`evidence/mtp-server-benchmark-20260820T150745Z`, 98.27/103.62/102.98 tok/s, 5144/9282 accept 55.42%). Post-run preflight PASS.
- 2026-08-20 context candidate 262144 PASS: retrieval prompt 261160 (`evidence/long-context-20260820T152539Z`); soak (`evidence/agent-soak-20260820T152848Z`); MTP 97.55/102.98/102.35 tok/s 55.42% (`evidence/mtp-server-benchmark-20260820T152859Z`); VRAM 22847/24823 MiB, min free 7294 MiB. Promoted `PROFILE=agent` to `-c 262144`.
