#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/../../common/load-env.sh"

REPO_URL="https://github.com/ggerganov/llama.cpp.git"
SRC_DIR="${SCRIPT_DIR}/llama.cpp"
BUILD_DIR="${SRC_DIR}/build"
ENV_KEY="BIN_NAME"

REQUIRED_CMDS=(git cmake make gcc g++ nproc)

have_cmd() { command -v "$1" >/dev/null 2>&1; }

missing_pkgs=()
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! have_cmd "$cmd"; then
    case "$cmd" in
      git) missing_pkgs+=(git) ;;
      cmake) missing_pkgs+=(cmake) ;;
      make|gcc|g++) missing_pkgs+=(build-essential) ;;
      nproc) missing_pkgs+=(coreutils) ;;
    esac
  fi
done

readarray -t missing_pkgs < <(printf "%s\n" "${missing_pkgs[@]}" | awk '!x[$0]++')

if [ "${#missing_pkgs[@]}" -gt 0 ]; then
  sudo apt-get update
  sudo apt-get install -y "${missing_pkgs[@]}"
fi

# ---- HARD CLEAN old CUDA ----
sudo apt-get remove --purge -y nvidia-cuda-toolkit || true
sudo rm -rf /usr/include/cuda* || true

# ---- install NVIDIA CUDA if missing ----
if ! find /usr/local -maxdepth 1 -type d -name 'cuda-*' | grep -q .; then
  sudo apt-get update
  sudo apt-get install -y wget gnupg

  wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb

  sudo apt-get update
  sudo apt-get install -y cuda-toolkit
fi

# ---- detect CUDA dynamically ----
CUDA_HOME="$(find /usr/local -maxdepth 1 -type d -name 'cuda-*' | sort -V | tail -n1)"

if [ -z "${CUDA_HOME}" ]; then
  echo "No CUDA installation found under /usr/local" >&2
  exit 1
fi

export CUDA_HOME
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH:-}"

# ---- verify ----
if [ ! -f "${CUDA_HOME}/include/cuda_runtime.h" ]; then
  echo "cuda_runtime.h missing in ${CUDA_HOME}/include" >&2
  exit 1
fi

if [ ! -x "${CUDA_HOME}/bin/nvcc" ]; then
  echo "nvcc missing in ${CUDA_HOME}/bin" >&2
  exit 1
fi

echo "Using CUDA at: ${CUDA_HOME}"

# ---- clone/update ----
if [ ! -d "${SRC_DIR}/.git" ]; then
  git clone "${REPO_URL}" "${SRC_DIR}"
else
  git -C "${SRC_DIR}" pull --ff-only
fi

# ---- CLEAN BUILD DIR ----
rm -rf "${BUILD_DIR}"

# ---- build ----
cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
  -DGGML_CUDA=ON \
  -DCUDAToolkit_ROOT="${CUDA_HOME}" \
  -DCMAKE_CUDA_COMPILER="${CUDA_HOME}/bin/nvcc" \
  -DCMAKE_CUDA_ARCHITECTURES=native

cmake --build "${BUILD_DIR}" -j"$(nproc)"

# ---- package ----
COMMIT_ID="$(git -C "${SRC_DIR}" rev-parse --short HEAD)"

ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) ARCH="${ARCH_RAW}" ;;
esac

BUILD_NAME="llama-${COMMIT_ID}-bin-linux-cuda-${ARCH}"
OUT_DIR="${BIN_DIR}/${BUILD_NAME}"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

for bin in llama-cli llama-server llama-quantize llama-bench; do
  [ -f "${BUILD_DIR}/bin/${bin}" ] && cp "${BUILD_DIR}/bin/${bin}" "${OUT_DIR}/"
done

# ---- update .env files in ../run directory ----
# Find all .env files in ../run directory (excluding .example files) and update them
for env_file in ../run/.env*; do
  # Skip if no files match the pattern
  [ -f "$env_file" ] || continue

  # Skip files with .example in the name
  if [[ "$env_file" == *".example"* ]]; then
    continue
  fi

  # Update the BIN_NAME variable in the env file
  touch "$env_file"

  if grep -q "^${ENV_KEY}=" "$env_file"; then
    sed -i "s|^${ENV_KEY}=.*|${ENV_KEY}=${BUILD_NAME}|" "$env_file"
  else
    echo "${ENV_KEY}=${BUILD_NAME}" >> "$env_file"
  fi

  echo "Updated ${ENV_KEY}=${BUILD_NAME} in ${env_file}"
done

echo "Done. Binaries at: ${OUT_DIR}"