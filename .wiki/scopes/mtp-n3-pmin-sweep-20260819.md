# T012: MTP n=3 p-min Sweep

**Status:** Closed
**Created:** 2026-08-19
**Tags:** optimization, mtp, speculative-decoding

## Contract

Evaluate draft depth 3 without changing the production launcher. Keep the
accepted agent profile fixed at 128K, F16 KV, one slot, layer split,
`-b 1024 -ub 256`, fit target 4096 MiB/GPU, Flash Attention, and GPU KV.

Phase A compares existing `n=2,p-min=0` evidence with `n=3,p-min=0`, changing
only draft depth. Phase B holds `n=3` fixed and compares p-min 0, 0.1, and 0.5.

## Required Evidence

- Preflight and topology for every candidate
- Three-run short, medium, and long MTP server workloads
- First run retained as warm-up; mean TG from runs 2-3
- Drafted/accepted token totals and acceptance rate
- Completion token counts and `finish_reason` in raw responses
- Server startup log and post-matrix host preflight

## Matrix

- [x] `n=3,p-min=0`
- [x] `n=3,p-min=0.1`
- [x] `n=3,p-min=0.5`
- [x] Compare with accepted `n=2,p-min=0`
- [x] Record best measured parameter set

## Results And Closeout

| n-max | p-min | short tok/s | medium tok/s | long tok/s | accept | Evidence |
| ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 2 | 0 | 90.99 | 97.48 | 96.83 | 67.24% | `evidence/candidate-p-min-0-20260819T134027Z/` |
| 3 | 0 | **98.30** | **103.81** | **103.23** | 55.45% | `evidence/candidate-p-min-0-20260819T144819Z/` |
| 3 | 0.1 | 98.25 | 103.68 | 103.07 | 55.45% | `evidence/candidate-p-min-0p1-20260819T145000Z/` |
| 3 | 0.5 | 87.42 | 93.39 | 95.33 | 66.92% | `evidence/candidate-p-min-0p5-20260819T145139Z/` |

Against n=2,p-min=0, n=3,p-min=0 improved TG by 8.03%, 6.49%, and
6.61%. It retained identical completion token counts, response lengths, and
finish reasons across the benchmark workloads. p-min 0.1 was effectively tied
but fractionally slower. p-min 0.5 reduced throughput and changed long-output
lengths.

Production acceptance for n=3,p-min=0 passed under:

- `evidence/n3-pmin0-acceptance-20260819T145407Z/`
- `evidence/long-context-20260819T145422Z/` (130090 prompt tokens, `cobalt-73`, `finish_reason=stop`)
- `evidence/agent-soak-20260819T145522Z/` (20 deterministic tool-call turns)

**Decision:** promote `--spec-draft-n-max 3`; continue omitting
`--spec-draft-p-min` (effective p-min 0).
