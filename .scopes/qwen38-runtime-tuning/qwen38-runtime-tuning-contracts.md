---
description: Contracts for qwen38-runtime-tuning identity files and candidate knobs.
---

# qwen38-runtime-tuning Contracts

## Identity files

`evidence/model.sha256` format:

```text
<sha256><two spaces><absolute path>
```

`scripts/inspect-model.sh` must use `sha256sum -c` against that file. It must not write the file.

`evidence/hf-source.txt` required keys:

```text
hf_repo
hf_file
hf_pinned_revision
hf_lfs_sha256
hf_size_bytes
local_path
```

Rules:

- `hf_lfs_sha256` must equal the SHA in `evidence/model.sha256`.
- `hf_size_bytes` must equal `stat -c %s` of `local_path`.
- Live resolve of `hf_pinned_revision`/`hf_file` must return the same SHA and size.
- HEAD may differ in revision; if HEAD file SHA differs, FAIL.
- The inspect script must not rewrite pinned keys.

## Candidate knobs

Allowed changed variables for `scripts/candidate-server.sh`:

| Name | Flag | Allowed values this scope |
| --- | --- | --- |
| p-min | `--spec-draft-p-min` | 0, 0.60, 0.70, 0.75 |
| ubatch | `-ub` | 256, 512 |
| fit-target | `--fit-target` | deferred unless M2/M3 leave a clear next question |

Exactly one changed variable per process. n-max remains 2. Split mode remains `layer`. Host remains `127.0.0.1`.

## Requirement Boundary Notes

Production `scripts/llama-server.sh` is out of this contract. Candidate evidence must not be described as an accepted default. n-max=3, tensor split, and CPU offload are rejected here.

## Validation rules

- Preflight must pass before a candidate bench.
- MTP metrics must advance (`spec_decode_num_draft_tokens_total` and accepted tokens).
- Do not treat planned numbers as evidence.

## Security-sensitive fields

None. Do not store HF tokens. Public resolve headers only.
