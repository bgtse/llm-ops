# Setup steps for Proxmox VE & LXC with NVIDIA GPU support

## Setup

### 1. Prepare LXC at PVE

Setup Ubuntu LXC.

Mount this repo to LXC:

```sh
echo "mp0: /path/at/pve/to/llm-ops,mp=/path/inside/lxc/to/llm-ops" >> /etc/pve/lxc/lxc-id.conf
echo "mp1: /path/at/pve/to/your-models,mp=/path/inside/lxc/to/you-models" >> /etc/pve/lxc/lxc-id.conf # Optional
chown -R 100000:100000 /path/at/pve/to/llm-ops # Optional. Only if you want to write into llm-ops inside LXC
```

### 2. Prepare PVE

Prepare `./nvidia-setup/.env`. Refer `./nvidia-setup/.env.example`.

Then run:

```sh
./nvidia-setup/pve.install-nvidia-driver.sh
./nvidia-setup/pve.nvidia-devices.service.sh
./nvidia-setup/pve.nvidia-lxc.service.sh lxc-id # This service will start the LXC. No need to set start at boot for LXC.
```

## 3. Prepare LXC runtime

Install driver:

```sh
./nvidia-setup/ubuntu.install-nvidia-driver.sh
```

Prepare `./llama/.env`. Refer `./llama/.env.example`.

(Optional) Build llama CUDA (make sure disk space >= 24gb, much memory and as many CPU cores):

```sh
./llama/build-llama-cuda.sh # This script will update BIN_NAME inside .env
```

Gathering CUDA runtime libraries:

```sh
./llama/install-cuda-runtime-libs.sh # If you build llama CUDA on the same instance, this may be skipped
```

Run llama:

```sh
./llama/server.sh # llama server params can be added via .env file
```
