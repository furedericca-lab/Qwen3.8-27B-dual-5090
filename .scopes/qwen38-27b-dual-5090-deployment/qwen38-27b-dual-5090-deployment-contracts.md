---
description: API and schema contracts for qwen38-27b-dual-5090-deployment.
---

# qwen38-27b-dual-5090-deployment Contracts

## API Contracts

The canonical launcher exposes llama.cpp's localhost OpenAI-compatible API:

| Endpoint | Method | Use |
| --- | --- | --- |
| `/health` | GET | Server health probe |
| `/v1/models` | GET | Model discovery probe |
| `/v1/chat/completions` | POST | Chinese, JSON, Python, long-context, and tool-call probes |

The deployment wrapper does not create a separate API or alter endpoint schemas.

## Shared Types / Schemas

`probe-basic.sh` sends `model`, `messages`, `temperature`, and `max_tokens`. `soak-agent.py` additionally sends a single OpenAI function tool whose required `turn` integer must equal the expected turn.

## Event and Streaming Contracts

Streaming is not part of this baseline acceptance. The server's native behavior remains compatible with the pinned upstream binary.

## Error Model

Scripts exit nonzero on missing exact model, wrong file mode/filesystem, unacceptable host state, missing binary, invalid response JSON, empty/special-token response, failed needle retrieval, or invalid tool call.

## Validation and Compatibility Rules

The model SHA256, llama.cpp gitlink, runtime arguments, and host preflight are the compatibility baseline. Change one variable and compare retained evidence before changing the launcher.

## Requirement Boundary Notes

Tool calling is an acceptance requirement but not yet a result. MTP is absent because the inspected GGUF has no MTP tensors. Wider network exposure and API proxying require a separate explicit scope.
