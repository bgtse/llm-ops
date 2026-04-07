#!/usr/bin/env bash
set -e

echo "[1/4] Update"
apt update

echo "[2/4] Install base deps"
apt install -y wget gnupg

echo "[3/4] Add NVIDIA CUDA repo (Ubuntu 24.04)"
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt update

echo "[4/4] Install minimal CUDA runtime libs"
apt install -y \
    libcudart12 \
    libcublas12 \
    libcublaslt12 \
    libcurand10

echo "Done. Verifying..."

ldconfig

echo "Check libcudart:"
ldconfig -p | grep libcudart || true

echo "Finished!"
