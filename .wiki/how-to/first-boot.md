---
title: First Boot
type: how-to
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment, qwen38-runtime-tuning]
related_files: [scripts/build-llama.sh, scripts/inspect-model.sh, scripts/inspect-hf-source.sh, scripts/inspect-topology.sh, scripts/preflight.sh, scripts/llama-server.sh]
code_anchors: []
source_docs: [README.md, AGENTS.md]
tags: [first-boot, llama-cpp, validation]
last_checked: 2026-08-19
updated: 2026-08-19T21:40:00Z
---

# First Boot

1. Run `scripts/build-llama.sh`.
2. Run `scripts/inspect-model.sh`; it must verify `evidence/model.sha256` and must not rewrite it.
3. Run `scripts/inspect-hf-source.sh` to confirm the pinned Hugging Face revision and LFS SHA still match the local GGUF. This does not hash 29 GB.
4. Run `scripts/inspect-topology.sh` when recording dual-GPU evidence.
5. Run `scripts/preflight.sh`; do not continue from a boot with a host-integrity failure. It does not scan the GGUF SHA.
6. Reproduce the 32K smoke with `PROFILE=baseline scripts/llama-server.sh` when needed.
7. Run `scripts/probe-basic.sh` from another terminal.
8. Start the accepted production runtime with `PROFILE=agent scripts/llama-server.sh`.
9. Run `python3 scripts/probe-long-context.py --target-tokens 131072`, `python3 scripts/soak-agent.py --turns 20`, and `python3 scripts/benchmark-server-mtp.py` before acceptance.
10. Run `scripts/preflight.sh` again after the workload suite.

The launcher enables `draft-mtp` with accepted draft depth 3 and has no CPU-offload option. Its context is fixed by profile. Do not append ad-hoc arguments or alter speculative mode/depth without a separately validated production change. Candidate knobs belong in `scripts/candidate-server.sh`, not the production launcher.
