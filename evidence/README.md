# Evidence

Tracked evidence is limited to immutable model identity. Generated benchmark, probe, long-context, soak, topology, and candidate outputs are intentionally ignored. Preserve a selected acceptance run externally before pruning local evidence.

Tracked identity files:

```text
evidence/model.sha256     frozen local SHA256; inspect-model.sh verifies and does not overwrite it
evidence/hf-source.txt    pinned HF repo, revision, LFS SHA256, and size
```

Every accepted result must identify the model SHA256, llama.cpp SHA, kernel, driver, CUDA version, context, KV type, fit target, batch, and ubatch.
