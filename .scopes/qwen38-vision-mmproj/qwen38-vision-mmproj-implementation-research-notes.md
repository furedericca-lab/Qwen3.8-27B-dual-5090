---
description: Evidence and scored decisions for the Qwen3.8 vision deployment.
---

# qwen38-vision-mmproj Implementation Research Notes

## Problem Statement and Current Baseline

`scripts/llama-server.sh` launches the fixed
`RVN-Q8_0-multilingual-mtp.gguf` with 256K F16 KV, layer split, `-b 1024`,
`-ub 256`, MTP n-max 3, and the user-approved `--fit-target 2048,2048`.
The service unit passes `HOST=172.30.0.214`; direct launchers default to
loopback. The accepted production launcher passes the pinned `--mmproj` and
HF chat-template paths.

Observed local identity on 2026-08-21:

- model directory is on `/data/linux-fast` ext4;
- model, mmproj, and chat template are mode `0444`;
- mmproj is 629247008 bytes with SHA256
  `2e968a6af97ce35d8971890b257b9b7edabf20ad91450501fa53162a19ee33eb`;
- HF template is 8952 bytes with SHA256
  `c3cf9e34abf4f9e36c2d72165aa9c132d3e2a725b6c2586aaa3a8af9d7a81041`;
- upstream template SHA256 is
  `a4aee8afcf2e0711942cf848899be66016f8d14a889ff9ede07bca099c28f715`;
- `cmp` returned 1 and `diff -u` showed reasoning/preserve-thinking and tool
  argument handling differences.

## Gap Analysis

- `scripts/candidate-server.sh` previously had no mmproj or HF-template mode.
- `scripts/probe-basic.sh` had no caller-controlled evidence directory.
- No standard-library-only image probe existed.
- `evidence/hf-source.txt` contained duplicate mmproj and chat-template ETag
  keys; the associative-array parser masked the duplication.

## Decision Roundtable

| Decision | Requirement Clarity | Evidence Strength | User-Intent Confidence | Implementation Confidence | Risk/Reversibility | Outcome | Evidence Source | Conflict | Confidence Reason |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| Keep HF template separate | 5 | 5 | 5 | 5 | 5 | Selected and promoted after independent candidate validation | local `sha256sum`, `cmp`, `diff`, and template candidate evidence | none | byte comparison is direct evidence |
| Use fit target 2048 | 5 | 4 | 5 | 5 | 5 | Selected and accepted with fresh multimodal runtime evidence | explicit user instruction and fit-target candidate | none | approved target must be measured, not inherited |
| Use explicit local `--mmproj` | 5 | 5 | 5 | 5 | 5 | Selected and promoted after 32K and 256K gates | `evidence/hf-source.txt` and llama.cpp multimodal contract | none | local `-m` mode requires explicit projector |
| Require image semantic gate | 5 | 5 | 5 | 5 | 5 | Required and passed on candidate and production service | validation contract and local API probe | none | startup cannot prove vision correctness |
| Preserve MTP and 256K | 5 | 5 | 5 | 5 | 5 | Preserved and accepted with positive post-image metrics | `AGENTS.md`, launcher, and accepted runtime evidence | none | user explicitly froze these parameters |

## Selected Design and Rationale

The candidate launcher keeps a single default parameter set and adds explicit
selection modes. `template hf` changes only the template. `mmproj on` changes
only projector loading. `TEMPLATE=hf` is allowed only for the final combined
candidate after the template gate. `run-vision-candidate.sh` owns startup,
health/models snapshots, text-before, deterministic image, text-after, and MTP
metric evidence. Phase 6 promoted the accepted combined candidate to the
production launcher after the 256K and formal-service gates passed.

## Validation Strategy

Run `scripts/inspect-hf-source.sh`, `bash -n scripts/*.sh`,
`python3 -m py_compile scripts/probe-vision.py`, and `git diff --check`.
Stop the formal service before candidate loads. Run preflight before every
candidate benchmark, long-context request, acceptance test, and soak. Retain
each run under `evidence/` with server logs and GPU/RAM/swap snapshots.

## Risks and Unresolved Questions

- The llama.cpp fit estimator may not fully account for late mmproj GPU use;
  actual startup free VRAM is the deciding evidence.
- The HF template differences may alter tool-call framing even when text output
  appears normal; the 20-turn soak is required before promotion.
- A failed candidate must be reported with its log and the production service
  restored without silently changing additional runtime parameters.
