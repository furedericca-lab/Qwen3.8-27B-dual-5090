---
description: Technical documentation for qwen38-runtime-tuning.
---

# qwen38-runtime-tuning Technical Documentation

## Canonical architecture

```text
HF repo 0bserverx/Qwen3.8-27B-Heretic-Abliterated-Uncensored-GGUF
  revision pin + LFS SHA  --> evidence/hf-source.txt
local GGUF                 --> evidence/model.sha256 (verify-only)
inspect-model.sh           --> sha256sum -c + GGUF metadata
inspect-hf-source.sh       --> HF headers, no 29 GB hash
inspect-topology.sh        --> PCIe/P2P snapshot
llama-server.sh            --> frozen production agent/baseline
candidate-server.sh        --> one-variable override
run-mtp-candidate.sh       --> preflight, start, MTP bench, stop
```

Layer split pipelines layers and KV across CUDA0/CUDA1. A single decode token walks GPU0 then GPU1; it does not use both cards as a 2x memory-bandwidth pool.

## Key constraints and non-goals

- Production bind remains `127.0.0.1`.
- MTP remains `--spec-type draft-mtp --spec-draft-n-max 2`.
- Do not add `--no-kv-offload`.
- Do not hash the GGUF in preflight.

## Major Decisions and Trade-offs

Inherited from research notes: verify-only identity, candidate-only sweeps, topology as explanation rather than a split-mode change.

## Interfaces

- `evidence/model.sha256`: `sha256sum` check file with absolute model path.
- `evidence/hf-source.txt`: `key=value` pin consumed by `inspect-hf-source.sh`.
- Candidate runs: HTTP `127.0.0.1:8000` `/health`, `/metrics`, `/v1/chat/completions`.

## Operational behavior

Production: `PROFILE=agent scripts/llama-server.sh`.

Candidate: `scripts/run-mtp-candidate.sh p-min 0.60`. Stops any previous candidate on the same port only if this script started it; refuse if an unrelated `llama-server` is already listening.

## Observability and error handling

- Pinned-revision mismatch: FAIL with remote vs pinned SHA/size/revision.
- HEAD filename SHA/size drift: FAIL with `hf_head_status=file-drift`; do not rewrite the pin.
- Local SHA mismatch: FAIL; do not rewrite the expected hash.
- Topology script is observational and exits 0 after writing evidence unless nvidia-smi fails or GPU count != 2.
- Candidate harness records server log, preflight, GPU snapshots, and MTP summary.

## Security model

Localhost only. No tokens in `evidence/hf-source.txt`. HF queries use public API/resolve headers.

## Test strategy

Docs/scripts: `bash -n`, `python3 -m py_compile`, `git diff --check`.
Identity: `scripts/inspect-hf-source.sh`, `scripts/inspect-model.sh`.
Host: `scripts/inspect-topology.sh`, `scripts/preflight.sh` before benches.
Performance: `python3 scripts/benchmark-server-mtp.py` per candidate.
