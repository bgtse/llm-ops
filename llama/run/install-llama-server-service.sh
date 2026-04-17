#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

if [ -n "${1:-}" ] && [[ ! "$1" =~ ^- ]]; then
  ENV_FILE_RAW="$1"
  ENV_FILE="$1"
  shift
  source "${SCRIPT_DIR}/../../common/load-env.sh" "$ENV_FILE"
else
  echo "Usage: $0 <.env.name> [args...]"
  exit 1
fi

if systemctl is-active --quiet "llama-server-${LLAMA_ARG_PORT}.service"; then
  echo "Warning: A llama-server service on port ${LLAMA_ARG_PORT} is already running!"
  exit 1
fi

cat <<EOF > /etc/systemd/system/llama-server-${LLAMA_ARG_PORT}.service
[Unit]
Description=Llama server at ${LLAMA_ARG_PORT}. .env file is ${ENV_FILE_RAW}
After=systemd-modules-load.service
Requires=systemd-modules-load.service

[Service]
Restart=always
RestartSec=5
ExecStart=${SCRIPT_DIR}/server.sh "${ENV_FILE_RAW}" $@

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable llama-server-${LLAMA_ARG_PORT}.service