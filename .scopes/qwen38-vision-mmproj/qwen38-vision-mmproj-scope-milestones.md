---
description: Phase gates for the Qwen3.8 vision projector deployment scope.
---

# qwen38-vision-mmproj Scope Milestones

## In-scope

- Pinned auxiliary provenance cleanup and local mode checks.
- Byte-level HF/upstream template comparison and template-only candidate.
- User-approved fit target `2048,2048` baseline validation.
- GPU-offloaded mmproj candidate at 32K, followed by MTP and vision sequence
  validation.
- Final 256K retrieval, MTP benchmark, 20-turn soak, and production promotion
  only after all gates pass.

## Out-of-scope

- Editing `llama.cpp/`, changing its gitlink, or changing the model GGUF.
- Changing the systemd unit or its explicitly configured LAN host.
- CPU weight/KV offload, `--no-mmproj-offload`, KV quantization, tensor split,
  context reduction, ubatch changes, or MTP depth changes.
- Automatic Hugging Face downloads or HEAD promotion.

## Decision Log

- The HF template is not byte-identical to the current upstream template; keep
  its behavior as a separate candidate variable.
- `2048,2048` is an explicitly user-approved runtime target and is validated as
  the new baseline before mmproj promotion.
- The projector remains GPU-offloaded by llama.cpp default; no compensating
  flag is permitted.
- Production promotion is gated by real image recognition and post-image MTP,
  not startup or health alone.

## Milestones and Exit Criteria

| Phase | Gate | Exit criterion |
| --- | --- | --- |
| 0 | Provenance | deduplicated pin, HF gate PASS, three local artifacts mode 0444 |
| 1 | Template | size/SHA/cmp/diff retained; template candidate basic/tool/soak PASS if needed |
| 2 | Fit baseline | 2048 target starts with no CPU weight/KV offload and MTP text PASS |
| 3 | mmproj 32K | projector loads on both CUDA devices; health/models/vision sequence PASS |
| 4 | MTP regression | text/image/text retains positive drafted and accepted metrics |
| 5 | 256K | retrieval, vision, MTP benchmark, 20-turn soak, and post-run preflight PASS |
| 6 | Promotion | launcher uses accepted mmproj/template/fit target; production smoke PASS |

## Dependencies

Phase 0 blocks every candidate. Phase 1 and Phase 2 must pass before the mmproj
candidate. Phase 3 blocks Phase 4. Phase 4 blocks Phase 5. Phase 5 blocks
Phase 6.

## Escalation Triggers

- Any pinned identity mismatch or host-integrity gate failure.
- CUDA OOM, Xid, BAD_PAGE, crash, or CPU residency of model/KV/projector.
- Vision output not strict and semantically correct, or MTP metrics not positive
  after the third text request.
- A candidate requires changing a frozen runtime variable to start.
