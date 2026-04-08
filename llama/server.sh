#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../common/load-env.sh"

"${BIN_DIR}/${BIN_NAME}/llama-server" \
  --host "$SERVER_HOST" \
  --port "$SERVER_PORT" \
  -m "${MODEL_DIR}/${MODEL_NAME}" \
  -ngl "$GPU_LAYERS" \
  -c "$CONTEXT_SIZE" \
  --flash-attn on \
  --jinja \
  --metrics
