---
description: Execution and evidence hub for the Qwen3.8 vision projector scope.
---

# Phases Checklist: Qwen3.8 Vision mmproj

## Input

- `AGENTS.md`
- `README.md`
- `scripts/llama-server.sh`
- `.wiki/reference/hf-source.md`
- `evidence/hf-source.txt`
- `qwen38-vision-mmproj-scope-milestones.md`
- `phase-0-qwen38-vision-mmproj.md` through `phase-6-qwen38-vision-mmproj.md`

## Global Status Board

| Phase | Status | Completion | Health | Evidence |
| --- | --- | ---: | --- | --- |
| 0 Provenance | Complete | 100% | PASS | HF source gate PASS; local modes 0444 |
| 1 Template | Complete | 100% | PASS | HF template basic, soak, MTP, postflight PASS |
| 2 Fit baseline | Complete | 100% | PASS | fit candidate 2048x2048, basic, MTP, postflight PASS |
| 3 mmproj 32K | Complete | 100% | PASS | projector, models, vision sequence, postflight PASS |
| 4 MTP regression | Complete | 100% | PASS | text/image/text drafted=349 accepted=189 |
| 5 256K acceptance | Complete | 100% | PASS | 261160 retrieval, vision, MTP, soak, postflight PASS |
| 6 Promotion | Complete | 100% | PASS | production service smoke at 172.30.0.214:8000 PASS |

## Phase Records

### Phase 0: Provenance

- [x] Remove duplicate auxiliary ETag keys without changing pinned values.
- [x] Run `scripts/inspect-hf-source.sh` and retain output.
- [x] Confirm model, mmproj, and template are mode `0444`.

Evidence: `evidence/hf-source.txt`, HF gate output, and local stat record from 2026-08-21.
Issues: initial duplicate keys were masked by Bash associative-array overwrite.
Checkpoint: PASS; the HF source gate and local identity checks match.

### Phase 1: Template

- [x] Retain template size, SHA256, `cmp`, and `diff` output.
- [x] Run `template hf` candidate at the 2048 fit baseline.
- [x] Run basic Responses, tool-call soak, and MTP text validation.

Evidence: `evidence/template-comparison-20260821T131004Z/` and
`evidence/candidate-template-hf-20260821T130737Z/`.
Checkpoint: PASS; the HF template candidate passes independently and remains
unpromoted until the final combined candidate.

### Phase 2: Fit Baseline

- [x] Run fit-target-only candidate at `2048,2048` with upstream template.
- [x] Record startup free VRAM and no CPU weight/KV offload.
- [x] Run basic Responses and MTP benchmark with n-max 3.

Evidence: `evidence/candidate-fit-target-2048x2048-20260821T130242Z/` and post-run preflight.
Checkpoint: PASS; 2048 target starts and text/MTP remain healthy.

### Phase 3: mmproj 32K

- [x] Stop the formal service and confirm no llama-server process remains.
- [x] Run `PROFILE=baseline PORT=8001 scripts/run-vision-candidate.sh mmproj on`.
- [x] Confirm projector load, CUDA0/CUDA1, health/models, and image semantic PASS.

Evidence: `evidence/vision-candidate-mmproj-on-upstream-20260821T131202Z/`.
Checkpoint: PASS; `text -> image -> text` succeeds with no OOM or integrity event.

### Phase 4: MTP Regression

- [x] Confirm drafted and accepted metrics advance after the third text request.
- [x] Confirm n-max 3, F16 KV, ubatch 256, and fit target 2048 in config/logs.
- [x] Inspect CPU/KV/projector residency and post-run host gate.

Evidence: `evidence/vision-candidate-mmproj-on-upstream-20260821T131202Z/mtp-sequence-summary.json`, metrics, runtime checks, and GPU snapshots.
Checkpoint: PASS; multimodal turns do not disable or corrupt later MTP text decoding.

### Phase 5: 256K Acceptance

- [x] Run combined `TEMPLATE=hf` candidate only after Phase 1 passes.
- [x] Run 256K basic, vision, retrieval, MTP benchmark, and 20-turn soak.
- [x] Run preflight before each gate and after shutdown.

Evidence: `evidence/acceptance-256k-mmproj-hf-20260821T131526Z/`; startup free VRAM 8471/7336 MiB and minimum snapshot 8379/7294 MiB.
Checkpoint: PASS; all production-readiness gates pass with fit target 2048.

### Phase 6: Promotion

- [x] Add pinned `--mmproj` and accepted HF template path to the launcher.
- [x] Verify production command line, endpoint, health, models, and basic text.
- [x] Record final recommendation and residual risk; do not commit automatically.

Evidence: `evidence/production-vision-20260821T132416Z/`; service command line,
multimodal models, production vision, MTP metrics, and post-workload preflight
all PASS.
Checkpoint: PASS; production path matches the accepted candidate exactly.

## Verification Commands

```bash
bash -n scripts/*.sh
python3 -m py_compile scripts/probe-vision.py
git diff --check
```

## Final Release Gate

Promotion is complete. Phases 0-5 retain PASS evidence, and the unchanged
systemd unit now runs the promoted launcher at `172.30.0.214:8000`. A future
candidate failure does not authorize a hidden context, KV, ubatch, MTP, or
offload change.

## Final Release Gate Summary

- Template: non-identical; independent HF-template candidate PASS.
- Fit target: `2048,2048`; 256K multimodal startup free VRAM `8471/7336 MiB`.
- Vision: deterministic red/blue JSON PASS on candidate and production endpoint.
- MTP: sequence delta `drafted=349, accepted=189`; 256K benchmark
  `drafted=9258, accepted=5152`.
- 256K: retrieval input `261160`, 20-turn soak, all preflight gates PASS.
- Promotion recommendation: PASS; production launcher promoted without a systemd file change.
