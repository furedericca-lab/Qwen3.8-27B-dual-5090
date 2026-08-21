---
description: Runtime architecture and operational behavior for Qwen3.8 vision.
---

# qwen38-vision-mmproj Technical Documentation

## Canonical Architecture

```text
evidence/hf-source.txt
  -> scripts/inspect-hf-source.sh
  -> fixed model + mmproj + chat_template in /data/linux-fast/models/...
scripts/llama-server.sh
  -> llama.cpp/build/bin/llama-server
  -> CUDA0/CUDA1 layer split, GPU KV, GPU mmproj, Responses API
scripts/candidate-server.sh
  -> one controlled variable or final combined candidate
scripts/run-vision-candidate.sh
  -> startup, API, image, post-image MTP, and host evidence
```

## Key Constraints and Non-goals

- Production model remains the exact frozen multilingual MTP GGUF.
- Production target is 256K, F16 KV, `-b 1024`, `-ub 256`, fit target
  `2048,2048`, layer split, and draft-MTP n-max 3.
- Projector GPU offload is the llama.cpp default; no CPU weight/KV offload is
  allowed.
- Production service binds only to the explicit `172.30.0.214`; candidates use
  `127.0.0.1`.

## Major Decisions and Trade-offs

- The local model path uses an explicit `--mmproj` so the pinned projector is
  loaded while retaining llama.cpp's default GPU offload.
- The HF `chat_template.jinja` is selected only after byte comparison and an
  independent template candidate; its non-identical content is a deliberate
  provenance and behavior choice.
- `--fit-target 2048,2048` uses the newly approved per-GPU margin to fit the
  projector without changing context, KV type, ubatch, or MTP depth.
- Final promotion requires real red/blue image recognition, a text-image-text
  MTP sequence, 256K retrieval, and formal-service smoke.

## Interfaces and Data Flow

The vision probe submits an OpenAI Responses request containing one user message
with `input_text` and `input_image.image_url`. The image URL is a deterministic
PNG data URI generated in memory and written to evidence. llama.cpp converts the
Responses request to chat-completions content, decodes the image through the
mmproj, and returns a completed response with `output_text`.

## Operational Behavior

Stop `qwen38-27b.service` before candidate loads. Run a candidate on port 8001
or another free localhost port. `run-vision-candidate.sh` refuses an existing
llama-server, records the two-GPU topology, waits for `/health`, captures
`/v1/models`, then executes basic text and `text -> image -> text`. It stops
the candidate before the post-run preflight.

## Observability and Error Handling

Every candidate retains `server.log`, health/models JSON, metrics before/after,
startup/after GPU snapshots, memory and swap snapshots, runtime log filters,
and preflight output. `probe-vision.py` retains complete request, response,
headers, status, PNG, SHA, and summary files. OOM, Xid, BAD_PAGE, incomplete
Responses, special-token leakage, incorrect colors, or non-positive MTP metrics
are failures.

## Security and Hardening

The probe makes no network image request and stores no credentials. Candidate
binds are localhost-only. The production LAN bind is inherited from the tracked
user service and is not widened by this scope. HF provenance uses public HEAD
requests only and never rewrites pinned files.

## Test Strategy

- Static: `bash -n scripts/*.sh`, Python compilation, `git diff --check`.
- Identity: `scripts/inspect-hf-source.sh` and local mode/stat checks.
- Candidate: preflight, startup, `/health`, `/v1/models`, basic probe, vision
  probe, MTP metrics, GPU/RAM/swap snapshots, and post-run preflight.
- Acceptance: 256K retrieval, vision sequence, MTP server benchmark, 20-turn
  tool-call soak, and final production service smoke.
