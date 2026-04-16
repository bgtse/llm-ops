#!/bin/bash

# Check if port argument is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <port>"
  exit 1
fi

PORT="$1"

# Stop and disable the service
systemctl stop "llama-server-${PORT}.service"
systemctl disable "llama-server-${PORT}.service"

# Remove the service file
rm -f /etc/systemd/system/llama-server-${PORT}.service

# Reload systemd
systemctl daemon-reload

echo "Llama server service on port ${PORT} has been stopped, disabled, and uninstalled."