#!/usr/bin/env bash
set -euo pipefail

# Resolve the caller script directory (the script that sourced this file)
CALLER_SOURCE="${BASH_SOURCE[1]}"
CALLER_DIR="$(cd "$(dirname "${CALLER_SOURCE}")" && pwd -P)"

if [ -n "${1:-}" ]; then
  ENV_FILE="${CALLER_DIR}/$1"
else
  ENV_FILE="${CALLER_DIR}/.env"
fi

if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
else
  echo "Missing ${ENV_FILE}"
  exit 1
fi
