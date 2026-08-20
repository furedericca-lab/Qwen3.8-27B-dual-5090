---
title: Qwen3.8 ubatch long-prompt prefill sweep
type: implementation
status: historical
scope: qwen38-runtime-tuning
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/run-ubatch-sweep.sh, scripts/benchmark-ubatch-prefill.py]
code_anchors: []
source_docs: [.wiki/reference/runtime-tuning-results.md]
tags: [ubatch, prefill]
last_checked: 2026-08-20
updated: 2026-08-20T13:50:00Z
---

# T011: Qwen3.8 ubatch 长 Prompt 预填速度验证

**Status:** Closed
**Created:** 2026-08-19
**Author:** build
**Tags:** optimization, ubatch, prefill, long-context

---

## 背景：Qwen3.6 的历史教训

翻出旧 Qwen3.6-40B 的优化记录，发现 ubatch 参数并非凭感觉设定，而是通过专门的长 prompt prefill sweep 得出：

| 参数 | 实测结论 | 最终值 |
|------|---------|-------|
| `-ub 128` | prefill 明显慢 | 淘汰 |
| `-ub 256` | **8K/66K prompt 的 prefill 提升约 20–34%，decode 无惩罚，只多约 130 MiB/GPU** | **256** |
| `-ub 512` | OOM | 淘汰 |
| `-b 1024` | 最佳稳定点 | **1024** |
| `-b 2048` | 没有收益 | 淘汰 |

T009 原文结论：**在 8K 和 66K prompt 上测试 `ub=128/256/512`**，`ub=256` 获得 **+20–34% prefill**，zero decode penalty，额外 VRAM 约 130 MiB/GPU；`ub=512` OOM。最终 T010 冻结为 `b=1024 / ub=256`。

---

## 当前 Qwen3.8 的实验缺口

现有证据显示：

```text
ub256  91.21 / 97.76 / 97.17 (TG metrics, short prompt)
ub512  90.83 / 97.50 / 96.82 (TG metrics, short prompt)
```

这些 benchmark 都是**短 prompt、decode-heavy**场景，只能证明：

```text
TG (decode-throughput):
ub256 ≈ ub512
```

但**没有回答最关键的问题：long-prompt prefill speed 谁快**。

如果当初 Qwen3.6 也只做这种 decode benchmark，也会错误地认为"ubatch 没什么作用"。实际上它对 Agent 的**长上下文输入速度**有明显影响。

---

## 假设与目标

**工作假设：**

```text
Qwen3.8 很可能已经选择了正确的 ub=256：
- TG (short prompt): ub256 not worse than ub512
- Production context: stable at 128K
- Historical precedent: Qwen3.6 shows +20–34% prefill for ub=256 vs ub=128
```

**但要把 `ub=256` 真正称为"优化后冻结"，还缺最后一个实验：**

```text
32K / 64K / 128K prompts × ub=128/256/512
Metrics: prompt tok/s, TTFT, peak VRAM, OOM status
```

**不重复的项目：**

- `-b` batch size: Qwen3.6 已证明 1024 → 2048 无收益，Qwen3.8 当前也是 -b 1024，无迹象显示 logical batch 是瓶颈
- Decode-heavy benchmarks: 已有 MTP throughput data

---

## 实验设计

### 固定参数

- Model: `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-mtp.gguf`
- `-b 1024`: fixed
- `--fit on --fit-target 4096,4096`: fixed
- `--load-mode dio`: fixed
- Flash Attention + GPU KV + layer split: fixed
- MTP mode during this sweep: `--spec-type draft-mtp --spec-draft-n-max 2`
- Server context: 131072 for every run
- Bind: `127.0.0.1:18000`

### 变量组合

**Prompt envelopes:**
- 32K context, target prompt >= 31744 tokens
- 64K context, target prompt >= 64512 tokens
- 128K context, target prompt >= 130048 tokens

Each envelope reserves 1024 tokens for chat framing and generation. The server
context remains 131072 in all nine runs, so ubatch is the only runtime variable.

**Ubatch values:**
- ub=128
- ub=256
- ub=512

Total: 9 test runs

### 测量指标

每次 run 记录：

1. **Prompt processing speed**: prompt tok/s (prefill throughput)
2. **TTFT**: time-to-first-token
3. **Peak VRAM**: per-GPU peak usage during prefill
4. **OOM status**: success or failure reason
5. **Memory delta**: estimate MiB/GPU difference vs baseline

### 基准配置

Use `scripts/run-ubatch-sweep.sh`; it starts `scripts/candidate-server.sh` with
the `agent` profile and changes only `-ub`:

```bash
PROFILE=agent PORT=18000 ./scripts/candidate-server.sh ubatch 128
```

`scripts/benchmark-ubatch-prefill.py` tokenizes a deterministic prompt, requests
one output token with prompt caching disabled, and records:

- llama.cpp response `timings.prompt_per_second` and `timings.prompt_ms`
- wall-clock request time as TTFT approximation
- 200 ms `nvidia-smi` samples and per-GPU peak used VRAM
- response usage, completion count, and `finish_reason`

The previous interrupted run under `evidence/ubatch-long-prompt-20260819T220705Z/`
is invalid: its runner exited before the health check due to an unbound `PORT`
variable and produced no benchmark result.

---

## 决策标准

**Historical hypothesis only (not an acceptance result):**

```text
ub=128:
  - Slowest prefill (-20–34% vs ub=256)
  - Lowest VRAM
  - Safe margin

ub=256:
  - Fastest safe prefill (+20–34% vs ub=128)
  - Zero decode penalty
  - ~130 MiB/GPU extra VRAM
  - Candidate expected from historical evidence

ub=512:
  - OOM at one or more context sizes
  - Or marginal prefill gain vs cost
```

**Success criteria:**

1. Every attempted run has a passing preflight; failures are retained and the matrix continues
2. Clear winner identified for ubatch parameter
3. Evidence archived in `evidence/ubatch-long-prompt-sweep-YYYYMMDDTHHMMSSZ/`
4. Decision recorded in `.wiki/decisions/`

---

## Execution Plan

**Phase 1: Infrastructure prep (T011-A)**

- [x] Create evidence directory structure
- [x] Prepare runner script with config matrix
- [x] Verify model identity and preflight passes

**Phase 2: Run experiments (T011-B)**

- [ ] 32K prompt × ub=128/256/512
- [ ] 64K prompt × ub=128/256/512
- [ ] 128K prompt × ub=128/256/512
- [ ] Collect all logs, summary.txt, gpu samples

**Phase 3: Analysis & decision (T011-C)**

- [ ] Compare prompt tok/s across ubatch levels
- [ ] Compare TTFT trends
- [ ] Map VRAM usage and identify OOM boundary
- [ ] Write decision record
- [ ] Archive scope closeout

---

## Related References

- Old Qwen3.6 scope T009/T010 (archived repo)
- Current evidence: `candidate-ubatch-128-bench-`, `candidate-ubatch-256-*`, `candidate-ubatch-512-*`
- AGENTS.md ubatch change rule: "change exactly one runtime variable per comparison"

---

## Notes

**Why this matters:**

Agent workloads often involve long context inputs (documents, conversation history, retrieved passages). If ub=128 is 20–34% slower at prefilling than ub=256, that's **minutes of wasted time** on each agent turn. Yet the VRAM cost is minimal (~130 MiB/GPU), and there's zero decode penalty.

This experiment closes the gap between "ubatch works fine" and "ubatch is optimized".

---

## Results And Closeout

Retained evidence: `evidence/ubatch-long-prompt-20260819T142649Z/`.
All nine requests and the final host-integrity preflight passed.

| Context envelope | Actual prompt | ub=128 tok/s | ub=256 tok/s | ub=512 tok/s | 256 vs 128 | 512 vs 256 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 32K | 31758 | 2833.69 | **3889.23** | 3833.93 | **+37.25%** | -1.42% |
| 64K | 64527 | 2585.87 | **3270.22** | 3213.02 | **+26.47%** | -1.75% |
| 128K | 130065 | 2202.15 | **2359.25** | 2247.74 | **+7.13%** | -4.73% |

Peak used VRAM was stable across prompt lengths. Compared with ub=128,
ub=256 used +168 MiB on GPU0 and +346 MiB on GPU1. Moving from ub=256 to
ub=512 added another +338 MiB on GPU0 and +696 MiB on GPU1 without a PP gain.
No configuration OOMed.

**Decision:** freeze `-b 1024 -ub 256`. It is the fastest tested ubatch at all
three prompt lengths, retains the existing decode result, and uses less VRAM
than ub=512. The 32K and 64K gains reproduce the historical Qwen3.6 effect;
the gain narrows at 128K but remains positive.

- [x] 32K prompt x ub=128/256/512
- [x] 64K prompt x ub=128/256/512
- [x] 128K prompt x ub=128/256/512
- [x] Collect logs, response timings, and GPU samples
- [x] Compare PP, TTFT, VRAM, and OOM status
- [x] Record the accepted runtime decision
