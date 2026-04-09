#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../common/load-env.sh"

"${BIN_DIR}/${BIN_NAME}/llama-server" \
  --flash-attn on
