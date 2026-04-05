#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env.sh"

MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"

"${BIN_DIR}/${BIN_NAME}/llama-bench" \
  -m "$MODEL_PATH" \
  -ngl "$GPU_LAYERS" \
  -p 512,2048 \
  -n 128 \
  --flash-attn on \
  -t 10