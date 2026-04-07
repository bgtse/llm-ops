#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../common/load-env.sh"

echo "--- Step 1: Updating Host and Installing Dependencies ---"
apt update && apt install -y pve-headers-$(uname -r) build-essential dkms wget

echo "--- Step 2: Blacklisting Nouveau ---"
cat <<EOF > /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
EOF

# Update initramfs to apply blacklist
update-initramfs -u

echo "--- Step 3: Downloading NVIDIA Driver ${NVIDIA_DRIVER_VERSION} ---"
DOWNLOADED_FILE_NAME="NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
wget -O $DOWNLOADED_FILE_NAME "https://us.download.nvidia.com/tesla/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
chmod +x $DOWNLOADED_FILE_NAME

echo "--- Step 4: Installing Driver (DKMS enabled) ---"
# --dkms: ensures the driver rebuilds after Proxmox kernel updates
# -s: silent mode
"./$DOWNLOADED_FILE_NAME" --dkms -s --no-questions --no-kernel-module-source

echo "--- Step 5: Configuring UVM (Required for CUDA/LLMs) ---"
# This ensures the /dev/nvidia-uvm nodes are created on boot
cat <<EOF > /etc/modules-load.d/nvidia.conf
nvidia
nvidia_uvm
EOF

echo "--------------------------------------------------------"
echo "INSTALLATION COMPLETE."
echo "CRITICAL: You must REBOOT the Proxmox host now."
echo "--------------------------------------------------------"
