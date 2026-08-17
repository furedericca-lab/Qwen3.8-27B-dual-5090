---
title: Host Integrity
type: debugging
status: current
scope: qwen38-27b-dual-5090-deployment
related_scopes: [qwen38-27b-dual-5090-deployment]
related_files: [scripts/preflight.sh]
code_anchors: []
source_docs: [AGENTS.md]
tags: [kernel, nvidia, integrity]
last_checked: 2026-08-17
updated: 2026-08-17T15:15:00Z
---

# Host Integrity

Formal benchmark and acceptance evidence requires a clean current boot:

```bash
scripts/preflight.sh
```

It checks kernel taint, relevant kernel errors, NVIDIA state, RAM, and swap. `BAD_PAGE`, kernel Oops, general protection, page corruption, or NVIDIA Xid invalidates a run. An unrelated network-adapter `XID` is not an NVIDIA Xid.

For a failed model run, preserve the process exit status and inspect VRAM, RAM, swap, and kernel logs before diagnosing OOM.
