---
description: Scope boundaries and milestones for qwen38-27b-dual-5090-deployment.
---

# qwen38-27b-dual-5090-deployment Scope and Milestones

## In Scope

- Deployment-only repository initialization, origin configuration, and upstream submodule pin.
- Model identity, read-only protection, metadata record, and host preflight gate.
- CUDA build, 32K smoke, 128K F16 KV runtime baseline, and acceptance tooling.

## Out of Scope

- Changing either retired project's GitHub state.
- BF16/F16/Q6/IQ/MXFP quantization, model conversion, pruning, REAP, MTP tuning, vLLM, CPU offload, or a 256K production profile.

## Decision Log

| Boundary / Decision | Evidence Source | Evidence Strength | Conflict | Confidence | Confidence Reason | Result |
| Q8_0 only | user deployment contract and exact artifact inspection | 10 | none | 10 | fixed SHA256 and single serving path | preserved |
| Official llama.cpp | upstream CLI source and user contract | 9 | none | 10 | direct I/O and qwen35 are available upstream | preserved |
| No inherited MTP | metadata inspection | 10 | none | 10 | zero MTP tensors | preserved |

## Milestones

1. Repository and model identity: exact artifact, read-only mode, scoped docs, and clean preflight.
2. Upstream CUDA build: Release `120a` binary and two visible CUDA devices.
3. 32K smoke: model start, health/models endpoints, and basic behavior probe.
4. 128K baseline: F16 KV, long-context retrieval, resource snapshots, and no post-run integrity event.
5. Agent acceptance: 20-50 turn tool-call soak without empty responses, argument corruption, or runaway output.

## Dependencies

Phase 1 blocks every later phase. Phase 2 depends on Phase 1. Phase 3 depends on Phase 2. Phase 4 depends on Phase 3. Phase 5 depends on Phase 4.

## Exit Criteria

The scope closes when the model identity, upstream binary, 128K runtime, behavior suite, resource measurements, and a 20-50 turn soak are retained as successful evidence from an admissible host boot. Under a later explicit user authorization, the retired local DeepSeek/Qwen3.6 projects and Qwen3.6 model were removed; no GitHub project state changed.

## Escalation Triggers

- Escalate only when code/runtime evidence, authoritative wiki, and scope docs materially conflict and the conflict cannot be resolved from local evidence.
- Escalate for data deletion, permission semantics, production access model, or public API compatibility decisions outside the stated boundaries.
- Escalate when user-specified boundaries cannot be satisfied together.
