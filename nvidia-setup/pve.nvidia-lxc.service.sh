#!/bin/bash

# Check for required LXC ID
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <lxc-id>"
    exit 1
fi

LXC_ID=$1
# Determine the directory where this setup script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_FILE="${SCRIPT_DIR}/pve.generate-lxc-config.sh"

STABLE_PATH="/usr/local/bin/update-lxc-nvidia-config.sh"
SERVICE_NAME="nvidia-devices-for-lxc-${LXC_ID}.service"

# 1. Validation
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: ${SOURCE_FILE} not found."
    exit 1
fi

# 2. Copy script to stable path (overwrites if exists)
echo "--- Deploying script to ${STABLE_PATH} ---"
cp -f "$SOURCE_FILE" "$STABLE_PATH"
chmod +x "$STABLE_PATH"

# 3. Create or Overwrite the systemd service
echo "--- Creating/Updating systemd service: ${SERVICE_NAME} ---"

cat <<EOF > /etc/systemd/system/${SERVICE_NAME}
[Unit]
Description=Config NVIDIA devices for LXC ${LXC_ID}
After=nvidia-devices.service
ConditionPathExists=${STABLE_PATH}

[Service]
Type=oneshot
ExecStart=${STABLE_PATH} ${LXC_ID}
ExecStart=pct start ${LXC_ID}
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Reload and Enable
echo "--- Reloading systemd and enabling service ---"
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"

echo "--------------------------------------------------------"
echo "SUCCESS: LXC ${LXC_ID} will now auto-config on boot."
echo "Source: ${SOURCE_FILE}"
echo "Target: ${STABLE_PATH}"
echo "--------------------------------------------------------"