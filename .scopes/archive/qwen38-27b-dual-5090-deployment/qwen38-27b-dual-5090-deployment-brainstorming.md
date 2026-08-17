---
description: Brainstorming and decision framing for qwen38-27b-dual-5090-deployment.
---

# qwen38-27b-dual-5090-deployment Brainstorming

## Problem

Create a small, reproducible deployment project for the fixed RVN Q8_0 GGUF. The former DeepSeek and Qwen3.6 repositories remain untouched until the new runtime has independent acceptance evidence.

## Scope

The scope covers model identity, an upstream llama.cpp CUDA build, a 32K smoke, a measured 128K baseline, and a 20-50 turn local tool-call soak.

## Constraints

- Production model: `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0.gguf` only.
- The model is read-only, resides on ext4, and is not copied into Git.
- Upstream llama.cpp pin: `34af94cd9ab277632e27caeec2d41de2fd091b31`.
- The runtime is localhost-only, full GPU, F16 KV, Flash Attention, one slot, and no MTP.
- A current boot with `BAD_PAGE`, Oops, GPF, page corruption, or NVIDIA Xid invalidates acceptance evidence.

## Options

| Decision | Options Considered | Rationale | Research Note Link |
|---|---|---|---|
| Runtime source | Official upstream; historical fork | Upstream supplies `qwen35` and `--load-mode dio`; no missing function is evidenced. | [research notes](qwen38-27b-dual-5090-deployment-implementation-research-notes.md) |
| Initial KV/context | 128K F16; 32K F16 smoke; compressed KV | A 32K smoke proves loading before any 128K claim; F16 KV is quality-first. | [milestones](qwen38-27b-dual-5090-deployment-scope-milestones.md) |
| MTP | Enable by inheritance; omit | GGUF inspection reports zero MTP tensors. | [metadata](../../../.wiki/reference/model-metadata.md) |

## Decision Summary

Use the official upstream pin with a two-gate launch sequence: 32K smoke first, then independently evidenced 128K. Do not create `agent` or `long` profiles before benchmark and soak results exist.

## Risks

- CUDA build or model load can expose a host fault; stop evidence collection and preserve logs.
- The model's chat-template and tool-call behavior is unverified until runtime probes pass.
- 128K capacity and throughput are unverified.

## Open Questions

- Does the baseline pass tool calling without template adjustments?
- Does 128K F16 KV preserve sufficient minimum free VRAM on both GPUs?
