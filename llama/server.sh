#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
if [ -n "${1:-}" ]; then
  source "${SCRIPT_DIR}/../common/load-env.sh" "${1:-}"
else
  source "${SCRIPT_DIR}/../common/load-env.sh"
fi

"${BIN_DIR}/${BIN_NAME}/llama-server"
