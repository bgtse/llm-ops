# LLM Operations

- Support NVIDIA drivers for PVE + LXC
  - Tested on PVE `8.4.17`, `9.1.7`
  - Tested on LXC `Ubuntu 24.04`
  - Tested on some NVIDIA RTX `Ada`, `Blackwell` GPUs
- Support running `llama.cpp` on LXC
- Support running Claude CLI via Cloudflared service token proxy

## PVE + LXC Setup with NVIDIA

### 1. Prepare LXC

- Setup Ubuntu LXC.
- Mount neccessary resource to LXC:

```sh
echo "mp0: /path/at/pve/to/llm-ops,mp=/path/inside/lxc/to/llm-ops" >> /etc/pve/lxc/lxc-id.conf # mount this repo
chown -R 100000:100000 /path/at/pve/to/llm-ops # Support writing to mount directories
echo "mp1: /path/at/pve/to/your-models,mp=/path/inside/lxc/to/you-models" >> /etc/pve/lxc/lxc-id.conf # (Optional) mount your models
```

### 2. Prepare PVE

Prepare `./nvidia-setup/.env`. Refer `./nvidia-setup/.env.example`.

Then run:

```sh
./nvidia-setup/pve.install-nvidia-driver.sh
./nvidia-setup/pve.nvidia-devices.service.sh # Create systemd service for resolving nvidia device nodes at boot
./nvidia-setup/pve.nvidia-lxc.service.sh lxc-id # Create systemd service to update LXC config regarding the nvidia device nodes at boot. This service will start the LXC (pct start <lxc-id>).
```

### 3. Prepare CUDA binary

Better to run in a separated linux envinronment because it will install CUDA toolkit, which is disk-space consuming. Make sure disk space >= 24gb, as many CPU cores as possible.

Prepare `./llama/build/.env`. Refer `./llama/build/.env.example`. Output binary will be used for running llama.cpp server. Make sure it can be seen by the LXC which will run llama.cpp.

To build llama.cpp CUDA, run:

```sh
./llama/build/build-llama-cuda.sh # This script will update BIN_NAME inside all .env files at ./llama/run/.env*
```

### 4. Prepare LXC runtime

Install driver:

```sh
./nvidia-setup/ubuntu.install-nvidia-driver.sh
```

Prepare `./llama/run/.env` file. Refer `./llama/run/.env.server.example`. File can be named as you prefer. Llama server params via environment variables can be added into `.env` files.

Installing CUDA runtime libraries (If you build llama CUDA on the same instance, this might be skipped):

```sh
./llama/run/install-cuda-runtime-libs.sh
```

## Run llama.cpp server

### 1. Run llama mannually

```sh
./llama/run/server.sh # will load .env
./llama/run/server.sh .env.as-you-prefer # will load .env.as-you-prefer
./llama/run/server.sh .env.as-you-prefer --with-more-llama-option --and-more-llama-option # will load .env.as-you-prefer + direct llama options
```

### 2. Run llama.cpp as a service

`LLAMA_ARG_PORT` will be used as a part of service name. If you run multiple services, make sure port are unique.

```sh
./llama/run/install-llama-server-service.sh .env.as-you-prefer # will load .env.as-you-prefer
./llama/run/install-llama-server-service.sh .env.as-you-prefer --with-more option --and-more option # will load .env.as-you-prefer + direct options
```
