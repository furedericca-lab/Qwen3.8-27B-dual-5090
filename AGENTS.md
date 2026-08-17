# Qwen3.8-27B Dual-5090 Deployment Contract

## Source Of Truth

1. `AGENTS.md`
2. `README.md`
3. `scripts/llama-server.sh`
4. `.wiki/decisions/`
5. `.wiki/reference/`
6. `evidence/`

Planned commands and unexecuted tuning ideas are not evidence. Record a successful run before changing a production default.

## Mission

Deploy the fixed Qwen3.8-27B RVN / Heretic Abliterated Uncensored Q8_0 GGUF with upstream llama.cpp on two RTX 5090 GPUs. This is a deployment repository, not a model-production, quantization, pruning, or conversion project.

## Fixed Model Identity

The sole production artifact is:

```text
/data/linux-fast/models/Qwen3.8-27B-RVN-GGUF/RVN-Q8_0.gguf
```

The model directory must be on the `/data/linux-fast` ext4 mount. Never copy, redownload, requantize, repack, modify, or add the GGUF to Git. Its verified identity and parsed metadata live in `evidence/model.sha256` and `.wiki/reference/model-metadata.md`.

The sibling BF16 file is not a serving input. A model-path override is only allowed for an explicit model-identity scope; routine launchers always use the absolute Q8_0 path above.

## Runtime Contract

`llama.cpp/` is the official `ggml-org/llama.cpp` submodule pinned by this repository's gitlink. Do not edit the submodule or pull it independently. Upgrade it only through a candidate build, basic probe, benchmark, agent soak, and a committed parent pin.

`scripts/llama-server.sh` is the sole canonical server launcher. `agent` is the accepted production default: 128K, F16 KV, one slot, Flash Attention, GPU KV, two GPUs, and localhost. `baseline` is a fixed 32K smoke profile. No `long` profile exists until a 256K candidate is separately evidenced.

It uses `--load-mode dio`, `--fit on --fit-target 4096,4096`, and no CPU weight/KV offload. `--fit-target` is final free VRAM margin per GPU, not KV reservation: increasing it leaves more margin and may offload more weights. Do not add `--no-kv-offload`; GPU KV is llama.cpp's default.

The inspected production GGUF has no MTP tensors. Do not add speculative/MTP arguments unless a newly recorded model inspection and successful runtime initialization prove they are applicable.

## Change Rules

- Change exactly one runtime variable per comparison: fit target, ubatch, KV type, context, llama.cpp pin, or sampling.
- Start the OOM ladder with a smaller ubatch, then more fit margin, then KV type, then context. CPU offload is a last resort and requires explicit scope.
- Do not introduce vLLM, Python environments, model-making tooling, DeepSeek assets, Qwen3.6 settings, or historical benchmark data.
- Bind only to `127.0.0.1` unless the user explicitly authorizes a wider bind.

## Host Integrity Gate

Before every benchmark, long-context run, acceptance test, or soak, run `scripts/preflight.sh`. It fails if the current boot has `BAD_PAGE`, Oops, general protection, page corruption, or an NVIDIA Xid. A run after such an event is not acceptance evidence. Diagnose failures from VRAM, RAM, swap, kernel log, and process exit status; do not label every failure OOM.

The accepted kernel taint values are `0` and `4096` (the expected proprietary module taint). Do not mistake unrelated device `XID` log lines for NVIDIA Xid; the gate matches NVIDIA/NVRM evidence specifically.

## Validation

| Change | Required evidence |
| --- | --- |
| Scripts/docs | `bash -n`, Python compilation, `git diff --check` |
| llama.cpp pin/build | CMake success, `--version`, `--list-devices` shows CUDA0/CUDA1 |
| Model identity | exact path, Q8_0 metadata, size, SHA256, read-only mode |
| Server baseline | preflight, startup, `/health`, `/v1/models`, basic probe, GPU snapshot |
| Tuning | baseline-versus-candidate result with one changed variable |
| Production readiness | 128K evidence and 20-50 turn agent soak |

Never claim a context, throughput, tool-call behavior, or stability result that was not successfully run and retained under `evidence/`.
