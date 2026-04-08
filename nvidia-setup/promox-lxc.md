# Setup steps for Proxmox LXC with NVIDIA GPU support

## At PVE host

### 1. Create Ubuntu LXC

### 2. For host preparation

```sh
./pve.install-nvidia-driver.sh
```

### 3. For LXC preparation

```sh
chown -R 100000:100000 /root/llm-ops # Optional. Only if modification needed.
./pve.generate-lxc-config.sh >> /etc/pve/lxc/lxc-id.conf
echo "mp0: /root/llm-ops,mp=/root/llm-ops" >> /etc/pve/lxc/lxc-id.conf
echo "mp1: /root/llm-models,mp=/root/llm-models" >> /etc/pve/lxc/lxc-id.conf
```

## Inside LXC

If build cuda, make sure disk space >= 24gb

Run

```sh
./ubuntu.install-nvidia-driver.sh
```