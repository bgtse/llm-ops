#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../common/load-env.sh"

echo "--- Step 1: Installing LXC Dependencies ---"
apt update
apt install -y build-essential libglvnd-dev pkg-config kmod wget

echo "--- Step 2: Downloading Driver ${DRIVER_VERSION} ---"
DOWNLOADED_FILE_NAME="NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
wget -O $DOWNLOADED_FILE_NAME "https://us.download.nvidia.com/tesla/${NVIDIA_DRIVER_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER_VERSION}.run"
chmod +x $DOWNLOADED_FILE_NAME

echo "--- Step 3: Installing Driver (LXC/Container Mode) ---"
# --no-kernel-module: Use the Proxmox host's kernel
# -s: Silent mode
"./$DOWNLOADED_FILE_NAME" --no-kernel-module -s --no-questions

echo "--- Step 4: Verification ---"
if command -v nvidia-smi &> /dev/null
then
    nvidia-smi
    echo "------------------------------------------------------------"
    echo "SUCCESS: Driver installed and GPUs recognized."
    echo "------------------------------------------------------------"
else
    echo "------------------------------------------------------------"
    echo "ERROR: Installation failed or nvidia-smi not in PATH."
    echo "Try running 'ldconfig' and checking 'nvidia-smi' again."
    echo "------------------------------------------------------------"
fi