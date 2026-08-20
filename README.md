# Qwen3.8-27B RVN Q8_0 MTP on Dual RTX 5090

This repository deploys one fixed model through upstream llama.cpp:

```text
Qwen3.8-27B RVN / Heretic Abliterated Uncensored GGUF
Q8_0 with MTP
2 x RTX 5090
```

The sole production model remains outside Git at `/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0-multilingual-mtp.gguf`.

## Status

| Gate | Status |
| --- | --- |
| Repository and upstream pin | Ready |
| Model identity | Pass: `RVN-Q8_0-multilingual-mtp.gguf`, SHA256 `3979ca0b...`, mode 0444 |
| CUDA build | Pass |
| 32K smoke | Pass |
| MTP initialization | Pass: `draft-mtp`, n-max 3, layer split |
| 256K agent baseline | Pass on multilingual MTP: 261,160-token retrieval, `cobalt-73` |
| Agent soak | Pass at 256K: 20 deterministic tool-call turns |
| MTP server benchmark | Pass at 256K: n-max 3; 97.55-102.98 tok/s, 55.42% accept |
| HF remote identity | Pass: revision `1962512c`, LFS SHA `3979ca0b...` matches local |
| p-min / ubatch / draft-depth sweep | Measured; accepted `-ub 256`, n-max 3, p-min 0. See [tuning results](.wiki/reference/runtime-tuning-results.md) |

## Build

```bash
scripts/build-llama.sh
```

The script builds a Release CUDA binary for Blackwell (`120a`) and verifies the server version plus visible CUDA devices.

## Inspect And Start

```bash
scripts/inspect-model.sh
scripts/inspect-hf-source.sh
scripts/inspect-topology.sh
scripts/preflight.sh
scripts/llama-server.sh
```

`inspect-model.sh` verifies `evidence/model.sha256` with `sha256sum -c` and does not rewrite it. `inspect-hf-source.sh` compares the pinned Hugging Face revision and LFS SHA against live resolve headers without hashing 29 GB. Preflight still skips the SHA scan.

The canonical production command is `PROFILE=agent scripts/llama-server.sh`. It starts the accepted 256K F16-KV MTP agent profile and always binds to `127.0.0.1:8000`. Use `PROFILE=baseline` only to reproduce the 32K smoke. Context is fixed by the selected profile.

## Verification

With the server running:

```bash
scripts/probe-basic.sh
python3 scripts/probe-long-context.py --target-tokens 262144
python3 scripts/soak-agent.py --turns 20
python3 scripts/benchmark-server-mtp.py
```

After stopping the server, run `scripts/benchmark-runtime.sh`; it measures the target model only, not speculative server decoding. Generated probe, benchmark, long-context, and soak outputs are timestamped and ignored locally.

## Accepted Runtime Evidence

`evidence/benchmark-20260819T130345Z/` records an isolated two-GPU `llama-bench` run with the fixed MTP Q8_0 model, DIO, F16 KV, Flash Attention, `-b 1024`, and `-ub 256`. It is target-model throughput, not MTP server throughput:

| Test | Result |
| --- | ---: |
| PP512 | 4285.85 tok/s |
| PP4096 | 5553.95 tok/s |
| PP32768 | 5046.60 tok/s |
| TG128 | 52.68 tok/s |

The benchmark reported `CUDA0/CUDA1`; its preflight and post-run host gate passed with no swap use.

## Runtime Baseline

The production runtime uses the MTP head embedded in the fixed GGUF:

```text
Q8_0 MTP model, DIO, CUDA0+CUDA1, layer split, fit target 4096/4096,
256K F16 KV, Flash Attention, single parallel slot, draft-mtp n-max 3, localhost-only.
```

`--no-kv-offload` is intentionally absent because it moves KV to CPU RAM. `--fit-target` means residual per-GPU VRAM, not KV allocation.

See [AGENTS.md](AGENTS.md), the [first boot guide](.wiki/how-to/first-boot.md), [model metadata](.wiki/reference/model-metadata.md), [HF source pin](.wiki/reference/hf-source.md), and [dual-5090 topology](.wiki/reference/host-topology.md) before changing runtime parameters. Layer split does not double single-token TG; see [layer-split throughput](.wiki/concepts/layer-split-throughput.md).
