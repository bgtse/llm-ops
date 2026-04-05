#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/env.sh"

MODEL_PATH="${MODEL_DIR}/${MODEL_NAME}"

"${BIN_DIR}/${BIN_NAME}/llama-server" \
  --host "$HOST" \
  --port "$PORT" \
  -m "$MODEL_PATH" \
  -ngl "$GPU_LAYERS" \
  -c "$CONTEXT_SIZE" \
  --flash-attn on \
  --jinja \
  --metrics
