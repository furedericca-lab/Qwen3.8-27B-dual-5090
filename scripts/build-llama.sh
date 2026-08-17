#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
source_dir="$root/llama.cpp"
build_dir="$source_dir/build"
jobs=${JOBS:-$(nproc)}

for command in cmake ninja; do
  command -v "$command" >/dev/null || { echo "missing required command: $command" >&2; exit 1; }
done
test -e "$source_dir/.git" || { echo "llama.cpp submodule is not initialized" >&2; exit 1; }
command -v nvcc >/dev/null || { echo "missing CUDA compiler: nvcc" >&2; exit 1; }

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES=120a \
  -DLLAMA_CURL=OFF
cmake --build "$build_dir" --target llama-server llama-bench -j"$jobs"

server="$build_dir/bin/llama-server"
test -x "$server" || { echo "llama-server was not built" >&2; exit 1; }
"$server" --version
"$server" --list-devices
