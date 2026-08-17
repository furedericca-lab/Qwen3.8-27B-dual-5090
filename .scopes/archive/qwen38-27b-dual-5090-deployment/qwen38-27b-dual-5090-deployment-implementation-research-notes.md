---
description: Implementation research notes for qwen38-27b-dual-5090-deployment.
---

# qwen38-27b-dual-5090-deployment Implementation Research Notes

## Baseline (Current State)

- `llama.cpp/` is an official upstream submodule pinned at `34af94cd9ab277632e27caeec2d41de2fd091b31`.
- The production GGUF is 28,595,754,496 bytes, SHA256 `638be14a0062789de1bcc714dc04c3d108ff9c3db054a74aaf2f25cca321d7ca`, mode `0444`, architecture `qwen35`, file type 7, 64 blocks, 262144 native context, and 851 tensors.
- Metadata contains no `nextn_predict_layers` field and zero MTP tensors.
- `scripts/preflight.sh` passed on kernel `7.0.0-28-generic`, taint `4096`, driver `610.43.02`, with two RTX 5090 GPUs visible and no matching integrity event.

## Gap Analysis

The repository has scripts and documentation but no accepted CUDA binary, startup, behavior, capacity, performance, or soak evidence. The historical repositories contain incompatible model settings and must not supply runtime values.

## Candidate Designs and Trade-offs

- Use the official upstream pin: lowest maintenance and already supports direct I/O; candidate fork is deferred until a concrete upstream defect appears.
- Start F16 KV at 32K then 128K: preserves quality and isolates capacity evidence; Q8 KV is deferred to a long-context scope.
- Keep the launcher parameterless beyond controlled `CONTEXT`: it avoids undocumented runtime drift but requires explicit candidate scripts for future A/B testing.

## Decision Roundtable

| Decision | Requirement Clarity | Evidence Strength | Evidence Source | Conflict | User-Intent Confidence | Implementation Confidence | Risk/Reversibility | Confidence Reason | Outcome |
| Runtime source | 5 | 5 | upstream source and CLI docs | none | 5 | 5 | 5 | official support is directly inspected | upstream pin |
| Production artifact | 5 | 5 | filesystem, SHA256, GGUF reader | none | 5 | 5 | 5 | exact Q8_0 path is unique in directory | fixed RVN Q8_0 |
| MTP mode | 5 | 5 | GGUF tensor scan | none | 5 | 5 | 5 | zero MTP tensors | disabled |
| 128K default | 5 | 3 | user requirement, no runtime result | none | 5 | 4 | 3 | quality-first F16 KV but capacity is unproven | gated after 32K |

## Selected Design

Use the Q8_0 artifact and upstream pin with `--load-mode dio -dev CUDA0,CUDA1 -sm layer --fit on --fit-target 4096,4096 -ctk f16 -ctv f16 -np 1 -b 1024 -ub 256 -fa on`. The launcher has no `--no-kv-offload`, MTP, CPU offload, or custom sampler arguments.

## Validation Plan

1. `bash -n scripts/*.sh`, `python3 -m py_compile scripts/*.py`, `git diff --check`.
2. `scripts/inspect-model.sh` and `scripts/preflight.sh`.
3. `JOBS=18 scripts/build-llama.sh`, then verify `--version` and `--list-devices`.
4. Start the 32K server, run `scripts/probe-basic.sh`, then record GPU/RAM/kernel status.
5. Start `CONTEXT=131072 scripts/llama-server.sh`; run benchmark and long-context tests one variable at a time.
6. Run `python3 scripts/soak-agent.py --turns 20` only after tool-call smoke passes.

## Risks and Assumptions

`file_type=7` is recorded as Q8_0 by the GGUF convention and filename. Tool calling and chat-template behavior remain unverified. The scope does not authorize deletion of old repositories; the user explicitly authorized a push of this parent repository only. The official submodule remains unmodified and has no pushable fork change.
