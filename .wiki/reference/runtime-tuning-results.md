---
title: Runtime Tuning Results
type: reference
status: current
scope: qwen38-runtime-tuning
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/run-mtp-candidate.sh, scripts/candidate-server.sh, scripts/llama-server.sh]
code_anchors: []
source_docs: [.scopes/qwen38-runtime-tuning/task-plans/4phases-checklist.md]
tags: [tuning, p-min, ubatch, mtp]
last_checked: 2026-08-19
updated: 2026-08-19T14:00:00Z
---

# Runtime Tuning Results

One-variable MTP server candidates on 2026-08-19, `PROFILE=agent`, n-max=2, layer split, llama.cpp `34af94cd9`, model SHA `5d33641d47321dfbc6fd64ab927385f29b89af66bf5f7a61d5bb7af4d4c5b748`. Means exclude the warm-up run. Long completions often stopped at EOS before 4096 tokens.

## p-min at n-max=2, ubatch 256

| p-min | evidence | short tok/s | medium tok/s | long tok/s | drafted | accepted | accept |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | `evidence/candidate-p-min-0-20260819T134027Z` | 90.99 | 97.48 | 96.83 | 7023 | 4722 | 67.24% |
| 0.60 | `evidence/candidate-p-min-0p60-20260819T134206Z` | 78.92 | 86.24 | 85.35 | 5197 | 4307 | 82.87% |
| 0.70 | `evidence/candidate-p-min-0p70-20260819T134355Z` | 74.11 | 78.42 | 80.32 | 4982 | 4240 | 85.11% |
| 0.75 | `evidence/candidate-p-min-0p75-20260819T134558Z` | 81.22 | 80.43 | 81.55 | 4730 | 4317 | 91.27% |

Throughput winner: **p-min 0** (production omit/default). Higher p-min raised acceptance and lowered tok/s. Completions at p-min ≥ 0.60 also changed length versus the p-min 0 runs, so it is not a pure speed knob.

## ubatch at p-min default 0

| ubatch | evidence | short tok/s | medium tok/s | long tok/s | accept |
| --- | --- | ---: | ---: | ---: | ---: |
| 256 | `evidence/candidate-ubatch-256-20260819T134826Z` | 91.21 | 97.76 | 97.17 | 67.24% |
| 512 | `evidence/candidate-ubatch-512-20260819T135005Z` | 90.83 | 97.50 | 96.82 | 67.24% |

This harness is decode-heavy (short prompts). It does not measure long-prompt prefill. Keep production `-ub 256`. Do not run fit-target for TG.

## Long-prompt ubatch sweep

| envelope | actual prompt | ub=128 tok/s | ub=256 tok/s | ub=512 tok/s |
| --- | ---: | ---: | ---: | ---: |
| 32K | 31758 | 2833.69 | **3889.23** | 3833.93 |
| 64K | 64527 | 2585.87 | **3270.22** | 3213.02 |
| 128K | 130065 | 2202.15 | **2359.25** | 2247.74 |

Evidence: `evidence/ubatch-long-prompt-20260819T142649Z/`. All nine runs and
the post-run preflight passed. Freeze `-ub 256`; ub=512 used more VRAM and was
slower at every prompt length.

## n-max=3 at ubatch 256

| p-min | short tok/s | medium tok/s | long tok/s | accept | Evidence |
| ---: | ---: | ---: | ---: | ---: | --- |
| 0 | **98.30** | **103.81** | **103.23** | 55.45% | `evidence/candidate-p-min-0-20260819T144819Z/` |
| 0.1 | 98.25 | 103.68 | 103.07 | 55.45% | `evidence/candidate-p-min-0p1-20260819T145000Z/` |
| 0.5 | 87.42 | 93.39 | 95.33 | 66.92% | `evidence/candidate-p-min-0p5-20260819T145139Z/` |

n-max=3,p-min=0 beat the n-max=2,p-min=0 baseline by 8.03%, 6.49%, and
6.61%. Completion lengths and finish reasons matched the baseline. Its basic
probe, 130090-token retrieval, 20-turn tool soak, and post-run preflight passed.

## Production

`scripts/llama-server.sh` uses `-b 1024 -ub 256`, n-max 3, layer split, and
omits `--spec-draft-p-min` (effective p-min 0).
