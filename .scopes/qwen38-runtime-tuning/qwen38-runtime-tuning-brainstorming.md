---
description: Decision path for qwen38-runtime-tuning. Production remains frozen.
---

# qwen38-runtime-tuning Brainstorming

## Problem

Commit `082e391` accepted a stable 128K MTP production baseline. It did not lock Hugging Face remote identity, did not record PCIe/P2P topology, and did not sweep MTP runtime knobs. Dual-5090 TG near 95 tok/s is not a 2x-bandwidth failure; layer split pipelines layers across GPUs.

## Options considered

| Option | Keep | Reject |
| --- | --- | --- |
| Verify frozen SHA in `inspect-model.sh`; pin HF revision + LFS SHA | yes | overwrite `evidence/model.sha256` on every inspect |
| Record topology; interpret PHB + P2P `GNS` as capacity/residency, not 2x TG | yes | treat missing P2P as a production defect |
| Sweep `--spec-draft-p-min` at n-max=2 | yes | change n-max to 3 in this scope |
| Sweep ubatch 256 vs 512 after best p-min | yes | expect TG to jump from ~95 to 120+ |
| Tensor split for same-layer parallel decode | no | experimental; Qwen3.8 MTP multi-GPU lockup still open |
| Change production `scripts/llama-server.sh` before candidate evidence | no | keep agent profile pinned |

## Decision Summary

Verify-only identity, record topology, candidate p-min then ubatch, freeze production, stop before n-max=3 and tensor split.

## Selected path

1. Lock provenance and topology with verify-only scripts.
2. Candidate-only MTP server runs: p-min `0 / 0.60 / 0.70 / 0.75`.
3. At the best p-min, compare ubatch 256 vs 512.
4. Stop. Do not promote a candidate into production without a measured win and a later production-change scope.
