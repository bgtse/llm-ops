#!/bin/bash

set -e

CTID="$1"

if [ -z "$CTID" ]; then
  echo "Usage: $0 <CTID>"
  exit 1
fi

CONF="/etc/pve/lxc/${CTID}.conf"

# Define the paths to scan
DEV_NODES=$(find /dev -maxdepth 1 -name "nvidia*" -type c)
CAP_NODES=$(find /dev/nvidia-caps -type c 2>/dev/null)

TMP=$(mktemp)

# Remove ALL existing device + mount entries
grep -vE "^lxc\.cgroup2\.devices\.allow|^lxc\.mount\.entry" "$CONF" > "$TMP"

# 1. Identify Unique Major Numbers for cgroup2
MAJORS=$(ls -l $DEV_NODES $CAP_NODES 2>/dev/null | awk '{print $5}' | sed 's/,//' | sort -u)

for major in $MAJORS; do
    echo "lxc.cgroup2.devices.allow: c $major:* rwm" >> "$TMP"
done

# 2. Generate Bind Mount Entries
format_mount() {
    local node=$1
    local target="${node#/}"
    echo "lxc.mount.entry: $node $target none bind,optional,create=file" >> "$TMP"
}

# Process standard nodes
for node in $(echo "$DEV_NODES" | sort); do
    format_mount "$node"
done

# Process capability nodes
for node in $(echo "$CAP_NODES" | sort); do
    format_mount "$node"
done

# Replace config
mv "$TMP" "$CONF"

echo "Updated LXC config: $CONF"