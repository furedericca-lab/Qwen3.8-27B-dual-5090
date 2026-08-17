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
| CUDA build | Pending |
| 32K smoke | Pending |
| 128K baseline | Partial: startup and 62K retrieval pass; isolated PP/TG pending |
| Agent soak | 20-turn tool-call pass |

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

The first server run is only a 32K smoke. Set `CONTEXT=131072` only after the smoke evidence is retained. The launcher always binds to `127.0.0.1:8000`.

## Verification

With the server running:

```bash
scripts/probe-basic.sh
scripts/benchmark-runtime.sh
python3 scripts/probe-long-context.py --target-tokens 32768
python3 scripts/soak-agent.py --turns 20
```

`probe-long-context.py` and `soak-agent.py` are acceptance tools, not claims of completed acceptance. They create timestamped, ignored evidence directories.

## Runtime Baseline

The initial runtime has no MTP or special sampler settings:

```text
Q8_0 model, DIO, CUDA0+CUDA1, layer split, fit target 4096/4096,
F16 KV, Flash Attention, single parallel slot, localhost-only.
```

`--no-kv-offload` is intentionally absent because it moves KV to CPU RAM. `--fit-target` means residual per-GPU VRAM, not KV allocation.

See [AGENTS.md](AGENTS.md), the [first boot guide](.wiki/how-to/first-boot.md), and [model metadata](.wiki/reference/model-metadata.md) before changing runtime parameters.
