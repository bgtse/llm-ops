#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../common/load-env.sh"

"${BIN_DIR}/${BIN_NAME}/llama-bench" \
  -m "$LLAMA_ARG_MODEL" \
  -ngl "$LLAMA_ARG_N_GPU_LAYERS" \
  --flash-attn on \
  -p 512,2048 \
  -n 128 \
  -t 10