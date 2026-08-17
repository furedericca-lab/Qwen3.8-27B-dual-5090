---
title: First Boot
type: how-to
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/build-llama.sh, scripts/inspect-model.sh, scripts/preflight.sh, scripts/llama-server.sh]
code_anchors: []
source_docs: [README.md, AGENTS.md]
tags: [first-boot, llama-cpp, validation]
last_checked: 2026-08-17
updated: 2026-08-17T15:30:00Z
---

# First Boot

1. Run `scripts/build-llama.sh`.
2. Run `scripts/inspect-model.sh` and confirm the recorded identity.
3. Run `scripts/preflight.sh`; do not continue from a boot with a host-integrity failure.
4. Reproduce the 32K smoke with `PROFILE=baseline scripts/llama-server.sh` when needed.
5. Run `scripts/probe-basic.sh` from another terminal.
6. Start the accepted production runtime with `PROFILE=agent scripts/llama-server.sh`.

The launcher has no MTP or CPU-offload option. Its context is fixed by profile. Do not append ad-hoc arguments to it; test a changed variable through an explicit, recorded candidate.
