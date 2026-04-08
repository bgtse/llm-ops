#!/bin/bash

# Define the paths to scan
DEV_NODES=$(find /dev -maxdepth 1 -name "nvidia*" -type c)
CAP_NODES=$(find /dev/nvidia-caps -type c 2>/dev/null)

# 1. Identify Unique Major Numbers for cgroup2
MAJORS=$(ls -l $DEV_NODES $CAP_NODES 2>/dev/null | awk '{print $5}' | sed 's/,//' | sort -u)

echo "# Allow the NVIDIA Major Numbers"
for major in $MAJORS; do
    echo "lxc.cgroup2.devices.allow: c $major:* rwm"
done

echo ""

# 2. Generate Bind Mount Entries
echo "# Bind Mount the Device Nodes"

# Function to format the lxc.mount.entry
format_mount() {
    local node=$1
    # Remove leading slash for the container's target path
    local target="${node#/}"
    echo "lxc.mount.entry: $node $target none bind,optional,create=file"
}

# Process standard nodes
for node in $(echo "$DEV_NODES" | sort); do
    format_mount "$node"
done

# Process capability nodes
for node in $(echo "$CAP_NODES" | sort); do
    format_mount "$node"
done