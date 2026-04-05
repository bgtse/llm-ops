#!/usr/bin/env bash
set -euo pipefail

# ---- resolve script dir ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# ---- load .env (optional) ----
source "${SCRIPT_DIR}/env.sh"


# ---- config ----
REPO_URL="https://github.com/ggerganov/llama.cpp.git"
SRC_DIR="${SCRIPT_DIR}/llama.cpp"
BUILD_DIR="${SRC_DIR}/build"

# BIN_DIR can be overridden in .env
BIN_DIR="${BIN_DIR:-${SCRIPT_DIR}/bin}"

REQUIRED_CMDS=(git cmake make gcc g++ nproc nvcc)

# ---- helpers ----
have_cmd() { command -v "$1" >/dev/null 2>&1; }

missing_pkgs=()

for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! have_cmd "$cmd"; then
    case "$cmd" in
      git) missing_pkgs+=(git) ;;
      cmake) missing_pkgs+=(cmake) ;;
      make|gcc|g++) missing_pkgs+=(build-essential) ;;
      nproc) missing_pkgs+=(coreutils) ;;
      nvcc) missing_pkgs+=(nvidia-cuda-toolkit) ;;
    esac
  fi
done

# dedupe packages
readarray -t missing_pkgs < <(printf "%s\n" "${missing_pkgs[@]}" | awk '!x[$0]++')

if [ "${#missing_pkgs[@]}" -gt 0 ]; then
  sudo apt-get update
  sudo apt-get install -y "${missing_pkgs[@]}"
fi

# ---- clone/update repo ----
if [ ! -d "${SRC_DIR}/.git" ]; then
  git clone "${REPO_URL}" "${SRC_DIR}"
else
  git -C "${SRC_DIR}" pull --ff-only
fi

# ---- build (CUDA) ----
cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" -DGGML_CUDA=ON
cmake --build "${BUILD_DIR}" -j"$(nproc)"

# ---- detect commit & arch ----
COMMIT_ID="$(git -C "${SRC_DIR}" rev-parse --short HEAD)"

ARCH_RAW="$(uname -m)"
case "${ARCH_RAW}" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) ARCH="${ARCH_RAW}" ;;
esac

OUT_DIR="${BIN_DIR}/llama-${COMMIT_ID}-bin-linux-cuda-${ARCH}"

# ---- prepare output ----
rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

# ---- copy binaries ----
BINARIES=(llama-cli llama-server llama-quantize llama-bench)

for bin in "${BINARIES[@]}"; do
  if [ -f "${BUILD_DIR}/bin/${bin}" ]; then
    cp "${BUILD_DIR}/bin/${bin}" "${OUT_DIR}/"
  fi
done

echo "Done. Binaries at: ${OUT_DIR}"