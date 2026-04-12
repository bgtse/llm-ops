cat <<EOF > /etc/systemd/system/nvidia-devices.service
[Unit]
Description=Create NVIDIA device nodes
After=systemd-modules-load.service
Requires=systemd-modules-load.service

[Service]
Type=oneshot
ExecStartPre=/bin/bash -c 'for i in {1..10}; do lsmod | grep -q nvidia && break || sleep 1; done'
ExecStartPre=/bin/bash -c 'for i in {1..10}; do nvidia-smi >/dev/null 2>&1 && break || sleep 1; done'
ExecStart=/usr/bin/nvidia-modprobe -u -c=0

RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reexec
systemctl enable nvidia-devices.service