# Work upto Blackwell generation GPUs

#!/usr/bin/env bash
set -eu
set -o pipefail || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../../common/load-env.sh"

echo "[1/5] Update"
apt-get update

echo "[2/5] Install base deps"
apt-get install -y wget gnupg

echo "[3/5] Add NVIDIA CUDA repo (Ubuntu 24.04)"
if ! ls /etc/apt/sources.list.d/*cuda* >/dev/null 2>&1; then
  wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  dpkg -i cuda-keyring_1.1-1_all.deb
fi
apt-get update

echo "[4/5] Detect CUDA version from binary"

LLAMA_BIN="$(find "${BIN_DIR}" -type f -name "llama-server" | head -n1)"

if [ -z "${LLAMA_BIN}" ]; then
  echo "llama-server not found in ${BIN_DIR}" >&2
  exit 1
fi

CUDA_MAJOR="$(ldd "${LLAMA_BIN}" | grep libcudart | sed -E 's/.*so\.([0-9]+).*/\1/' | head -n1)"

if [ -z "${CUDA_MAJOR}" ]; then
  echo "Failed to detect CUDA version" >&2
  exit 1
fi

echo "Detected CUDA major version: ${CUDA_MAJOR}"

echo "[5/5] Install minimal CUDA runtime"

# find available cuda-runtime-X-Y package
CUDA_RUNTIME_PKG="$(apt-cache search ^cuda-runtime | grep "cuda-runtime-${CUDA_MAJOR}-" | head -n1 | awk '{print $1}')"

if [ -n "${CUDA_RUNTIME_PKG}" ]; then
  echo "Installing ${CUDA_RUNTIME_PKG}"
  apt-get install -y "${CUDA_RUNTIME_PKG}"
else
  echo "No cuda-runtime package found for CUDA ${CUDA_MAJOR}"
  echo "Fallback: installing individual libs if available"

  # try legacy / partial packages
  apt-get install -y \
    "libcudart${CUDA_MAJOR}" \
    "libcublas${CUDA_MAJOR}" \
    "libcublaslt${CUDA_MAJOR}" \
    "libcurand${CUDA_MAJOR}" \
  || {
    echo "ERROR: cannot find minimal runtime packages"
    exit 1
  }
fi

echo "Updating linker cache"
ldconfig

echo "Verifying:"
ldconfig -p | grep libcudart || true

echo "Done. Minimal CUDA runtime installed."