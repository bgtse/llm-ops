# LLM Operations for PVE and LXC and NVIDIA GPUs

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

## 3. Prepare CUDA binary

Better to run in a separated linux envinronment because it will install CUDA toolkit, which is disk-space consuming. Make sure disk space >= 24gb, as many CPU cores as possible.

Prepare `./llama/build/.env`. Refer `./llama/build/.env.example`.

To build llama CUDA:

```sh
./llama/build/build-llama-cuda.sh # This script will update BIN_NAME inside all .env files at ./llama/run/.env*
```

## 4. Prepare LXC runtime

Install driver:

```sh
./nvidia-setup/ubuntu.install-nvidia-driver.sh
```

Prepare `./llama/run/.env` file. Refer `./llama/run/.env.server.example`. File can be named as you prefer. Llama server env vars as params can be added via `.env` files.

Gathering CUDA runtime libraries (If you build llama CUDA on the same instance, this might be skipped):

```sh
./llama/run/install-cuda-runtime-libs.sh
```

## 5. Run

Run llama mannually

```sh
./llama/run/server.sh # will load .env
./llama/run/server.sh .env.as-you-prefer # will load .env.as-you-prefer
```

Run llama as a service. For each .env* file used for service, `LLAMA_ARG_PORT` must be unique.

```sh
./llama/run/install-llama-server-service.sh .env.as-you-prefer
```
