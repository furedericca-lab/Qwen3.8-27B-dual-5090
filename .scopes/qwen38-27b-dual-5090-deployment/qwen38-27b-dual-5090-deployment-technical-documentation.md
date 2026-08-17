---
description: Canonical technical architecture for qwen38-27b-dual-5090-deployment.
---

# qwen38-27b-dual-5090-deployment Technical Documentation

## Canonical Architecture

`scripts/build-llama.sh` builds the pinned `llama.cpp/` submodule. `scripts/inspect-model.sh` validates the fixed external GGUF. `scripts/preflight.sh` gates host integrity. `scripts/llama-server.sh` is the only server entry point. Probe, benchmark, long-context, and soak scripts write ignored timestamped evidence under `evidence/`.

## Key Constraints and Non-Goals

The external model is immutable and never enters Git. Runtime is two CUDA devices, F16 KV, Flash Attention, one slot, direct I/O, and localhost only. No MTP or CPU offload is configured. No model-making capability exists in this repository.

## Major Decisions and Trade-offs

The 4096 MiB fit target is a conservative unverified initial margin and must be compared using minimum free VRAM. A 32K smoke deliberately precedes the 128K production candidate. F16 KV is chosen before compressed KV because the model weights leave substantial dual-GPU capacity to measure.

## Module Boundaries and Data Flow

GGUF on `/data/linux-fast` -> llama-server DIO load -> CUDA0/CUDA1 layer split -> localhost OpenAI-compatible endpoints. Scripts never write the GGUF. API result and hardware snapshots -> timestamped evidence directory.

## Interfaces and Contracts

The server exposes llama.cpp's `/health`, `/v1/models`, and `/v1/chat/completions` endpoints on `127.0.0.1:8000`. `probe-basic.sh`, `probe-long-context.py`, and `soak-agent.py` are clients of those endpoints.

## Security and Reliability

The server does not bind to a network interface. The preflight gate rejects material kernel/NVIDIA error evidence and unexpected taint. Model selection is fixed to an exact absolute Q8_0 path; no glob result is used as a runtime fallback.

## Test Strategy

Static script checks and preflight precede build. Build checks require binary version and CUDA0/CUDA1 visibility. Runtime progression is health -> basic behavior -> 128K/long context -> agent soak, with a preflight before formal workload tests.
