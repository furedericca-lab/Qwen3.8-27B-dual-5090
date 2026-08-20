---
description: Responses API client contract and user service for Qwen3.8 deployment.
---

# Qwen3.8 Responses API Contract

## Context

The canonical llama.cpp server already supports the OpenAI-compatible Responses API, but the repository probes and agent soak used `/v1/chat/completions`. The running production process remains the fixed multilingual MTP GGUF on two RTX 5090 GPUs.

## Findings

- `POST /v1/responses` is available in the pinned llama.cpp submodule.
- Non-streaming Responses return `status`, `output`, and `usage.input_tokens` / `usage.output_tokens`.
- Function tools use `function_call` and `function_call_output` input items.
- No existing user or system systemd unit named for llama, Qwen, vLLM, Ollama, TGI, or another model server was found before this change.

## Outcome

The repository's basic probe, long-context probe, MTP benchmark, prefill benchmark, and tool-call soak use `/v1/responses`. A tracked `systemd/qwen38-27b.service` unit calls the canonical launcher with the unchanged `agent` runtime profile and remains disabled unless the user explicitly enables it.

## Boundaries

- Keep the model path, MTP settings, GPU split, context, fit target, and localhost bind unchanged.
- Keep Chat Completions available through llama.cpp for compatibility; this change selects Responses API for repository clients.
- Do not start a second server while port `8000` is occupied.

## Verification Surface

- `bash -n scripts/*.sh`
- `python3 -m py_compile scripts/*.py`
- `git diff --check`
- `scripts/preflight.sh` before runtime acceptance
- `scripts/probe-basic.sh` and `scripts/soak-agent.py --turns 20` against `/v1/responses`
- `systemd-analyze verify systemd/qwen38-27b.service`
- `systemctl --user list-unit-files` and system service inventory for competing model units
