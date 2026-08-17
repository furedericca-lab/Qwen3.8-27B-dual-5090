# Qwen3.8-27B RVN Q8_0 on Dual RTX 5090

This repository deploys one fixed model through upstream llama.cpp:

```text
Qwen3.8-27B RVN / Heretic Abliterated Uncensored GGUF
Q8_0
2 x RTX 5090
```

The model remains outside Git at `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0.gguf`.

## Status

| Gate | Status |
| --- | --- |
| Repository and upstream pin | Ready |
| Model identity | Recorded |
| CUDA build | Pass |
| 32K smoke | Pass |
| 128K agent baseline | Pass: F16 KV, 62,438-token retrieval, isolated PP/TG |
| Agent soak | Pass: 20 deterministic tool-call turns |

## Build

```bash
scripts/build-llama.sh
```

The script builds a Release CUDA binary for Blackwell (`120a`) and verifies the server version plus visible CUDA devices.

## Inspect And Start

```bash
scripts/inspect-model.sh
scripts/preflight.sh
scripts/llama-server.sh
```

The canonical production command is `PROFILE=agent scripts/llama-server.sh`. It starts the accepted 128K F16-KV agent profile and always binds to `127.0.0.1:8000`. Use `PROFILE=baseline` only to reproduce the 32K smoke; context is fixed by the selected profile.

## Verification

With the server running:

```bash
scripts/probe-basic.sh
python3 scripts/probe-long-context.py --target-tokens 32768
python3 scripts/soak-agent.py --turns 20
```

After stopping the server, run `scripts/benchmark-runtime.sh`; it refuses to run against resident server VRAM. Generated probe, benchmark, long-context, and soak outputs are timestamped and ignored locally.

## Accepted Runtime Evidence

`evidence/benchmark-20260817T152536Z/` records an isolated two-GPU `llama-bench` run with the fixed Q8_0 model, DIO, F16 KV, Flash Attention, `-b 1024`, and `-ub 256`:

| Test | Result |
| --- | ---: |
| PP512 | 4303.88 tok/s |
| PP4096 | 5552.22 tok/s |
| PP32768 | 5059.20 tok/s |
| TG128 | 52.70 tok/s |

The benchmark reported `CUDA0/CUDA1`. Peak samples left 17,563 MiB free on GPU0 and 16,632 MiB free on GPU1; its post-run host gate passed with no swap use.

## Runtime Baseline

The initial runtime has no MTP or special sampler settings:

```text
Q8_0 model, DIO, CUDA0+CUDA1, layer split, fit target 4096/4096,
128K F16 KV, Flash Attention, single parallel slot, localhost-only.
```

`--no-kv-offload` is intentionally absent because it moves KV to CPU RAM. `--fit-target` means residual per-GPU VRAM, not KV allocation.

See [AGENTS.md](AGENTS.md), the [first boot guide](.wiki/how-to/first-boot.md), and [model metadata](.wiki/reference/model-metadata.md) before changing runtime parameters.
