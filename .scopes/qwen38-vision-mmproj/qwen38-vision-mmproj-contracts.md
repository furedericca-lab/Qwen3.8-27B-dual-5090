---
description: Contracts for the Qwen3.8 auxiliary vision artifacts and runtime promotion.
---

# qwen38-vision-mmproj Contracts

## Context

The repository has frozen a Qwen3.8 multilingual MTP Q8_0 GGUF and a validated
256K F16-KV llama.cpp runtime. The pinned model directory now also contains a
629247008-byte mmproj and an 8952-byte HF chat template. The production service
uses `HOST=172.30.0.214`, while direct launchers and candidates default to
localhost.

## Findings

- `evidence/hf-source.txt` pins both auxiliary files and the local files are
  mode `0444`.
- The HF template SHA is
  `c3cf9e34abf4f9e36c2d72165aa9c132d3e2a725b6c2586aaa3a8af9d7a81041`.
- The upstream `Qwen3.5-4B.jinja` SHA is
  `a4aee8afcf2e0711942cf848899be66016f8d14a889ff9ede07bca099c28f715`.
  The observed `cmp` result is non-zero, so template behavior requires its own
  candidate gate.
- The user explicitly approved `--fit-target 2048,2048` as the new runtime
  target. It must be validated again with the auxiliary artifact loaded.

## Outcome

Promote `--mmproj` and, only after its independent candidate passes, the pinned
HF template into `scripts/llama-server.sh`. Preserve 256K context, F16 KV,
`-b 1024`, `-ub 256`, layer split, GPU projector offload, and MTP n-max 3.

## Goals / Non-goals

Goals:

- Verify provenance and template identity without changing pinned values.
- Validate fit target 2048, template-only, mmproj-only, and final 256K runtime
  gates in dependency order.
- Retain startup logs, GPU/RAM/swap snapshots, API payloads/responses, and MTP
  metrics under timestamped ignored evidence directories.

Non-goals:

- No model GGUF modification, download, conversion, quantization, or submodule
  pin change.
- No systemd unit change, wider bind, CPU weight/KV offload, KV quantization,
  context reduction, MTP depth change, or new sampling mode.

## Requirement Boundary Notes

- This scope may add only the pinned GPU-offloaded mmproj, the independently
  accepted pinned HF template, and the user-approved `2048,2048` fit target.
- The existing 256K context, F16 KV, `-b 1024`, `-ub 256`, layer split, and MTP
  n-max 3 behavior are acceptance requirements, not tuning variables.
- Production promotion requires candidate evidence and a formal service smoke
  at `172.30.0.214:8000`; startup or health alone is insufficient.
- Systemd ownership, the llama.cpp submodule pin, the model GGUF, and pinned HF
  identities remain outside the change boundary.

## Target Files / Modules

- `scripts/llama-server.sh`
- `scripts/candidate-server.sh`
- `scripts/run-mtp-candidate.sh`
- `scripts/run-vision-candidate.sh`
- `scripts/probe-vision.py`
- `scripts/probe-basic.sh`
- `evidence/hf-source.txt`
- `AGENTS.md`, `README.md`, `.wiki/reference/`

## Candidate and API Contracts

- `scripts/candidate-server.sh template hf` selects only the pinned HF
  template.
- `scripts/candidate-server.sh mmproj on` adds only the pinned `--mmproj`.
- `TEMPLATE=hf ... candidate-server.sh mmproj on` is reserved for the final
  combined candidate after the template gate passes.
- Candidate HTTP traffic uses `http://127.0.0.1:$PORT/v1/responses`.
- Vision requests use `input_image.image_url` with a runtime-generated
  `data:image/png;base64,...` URI, `temperature=0`, `max_output_tokens=128`,
  and `chat_template_kwargs.enable_thinking=false`.
- A vision PASS requires HTTP success, `status=completed`, non-empty
  `output_text`, strict JSON color mapping (`left=red`, `right=blue`), and no
  leaked special tokens.

## Verification Surface

- `scripts/inspect-hf-source.sh` must PASS after provenance cleanup.
- `scripts/preflight.sh` must run before every benchmark, long-context test,
  acceptance test, and soak, and after each candidate run.
- Script changes require `bash -n`, Python compilation, and `git diff --check`.
- Runtime acceptance requires basic Responses API, `/health`, `/v1/models`,
  vision sequence `text -> image -> text`, positive drafted/accepted MTP
  metrics, 256K retrieval, MTP benchmark, and 20-turn tool soak.

## Boundaries, Escalation, and Rollback

Stop and report if the pinned remote identity drifts, preflight fails, the
candidate OOMs/crashes, GPU/KV residency is not as required, vision is
unsupported, or MTP metrics stop advancing. Do not compensate by changing
context, KV type, ubatch, fit target, or MTP depth inside this scope.

Rollback is to remove `--mmproj` and restore the upstream template path in
`scripts/llama-server.sh`; retain the pinned auxiliary files and evidence.
The 2048 fit target is the user-approved new target, but an unsuccessful
candidate must leave the prior running production process intact rather than
claiming an unvalidated promotion.

## Execution Log / Evidence Updates

Status: Complete.

- 2026-08-21: repository and active service inspected; service endpoint is
  `172.30.0.214:8000`.
- 2026-08-21: duplicate auxiliary ETag lines removed from
  `evidence/hf-source.txt`.
- 2026-08-21: HF source gate PASS with HEAD revision-only warning; fit-target
  candidate PASS at `evidence/candidate-fit-target-2048x2048-20260821T130242Z/`
  with positive MTP metrics and post-run preflight.
- 2026-08-21: template comparison `cmp=1` retained in
  `evidence/template-comparison-20260821T131004Z/`; template candidate PASS at
  `evidence/candidate-template-hf-20260821T130737Z/` with 20-turn soak.
- 2026-08-21: mmproj-only 32K candidate PASS at
  `evidence/vision-candidate-mmproj-on-upstream-20260821T131202Z/`; models
  advertised multimodal, vision recognized red/blue, and MTP remained positive.
- 2026-08-21: combined 256K acceptance PASS at
  `evidence/acceptance-256k-mmproj-hf-20260821T131526Z/`; retrieval input
  261160, vision/text sequence, 20-turn soak, MTP benchmark, and every
  preflight gate passed. Startup free VRAM was 8471/7336 MiB.
- 2026-08-21: formal production smoke PASS at
  `evidence/production-vision-20260821T132416Z/`; the unchanged
  `qwen38-27b.service` owns `172.30.0.214:8000`, `/v1/models` reports
  `completion,multimodal`, deterministic red/blue vision passed, the
  text-image-text MTP sequence remained positive, and post-run preflight
  passed. Production startup free VRAM was recorded in that evidence.
- 2026-08-21: after explicit user approval, advanced the provenance pin to
  current HF HEAD `20b94f0613b632b4848bbe3b1e05d9ee0c2b1608`; the pinned and
  HEAD GGUF/mmproj/template identities remained unchanged and the source gate
  now reports `hf_head_status=match`.
- 2026-08-21: scope closeout complete; no systemd change, llama.cpp submodule
  change, model change, or automatic download was performed. Repository
  publication remains an explicit user-controlled action.
