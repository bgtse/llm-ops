#!/bin/bash

# Configuration
DRIVER_VERSION="580.126.20"
DRIVER_URL="https://us.download.nvidia.com/tesla/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"

echo "--- Step 1: Installing LXC Dependencies ---"
apt update
apt install -y build-essential libglvnd-dev pkg-config kmod wget

echo "--- Step 2: Downloading Driver ${DRIVER_VERSION} ---"
wget -O nvidia-install.run "$DRIVER_URL"
chmod +x nvidia-install.run

echo "--- Step 3: Installing Driver (LXC/Container Mode) ---"
# --no-kernel-module: Use the Proxmox host's kernel
# -s: Silent mode
./nvidia-install.run --no-kernel-module -s --no-questions

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