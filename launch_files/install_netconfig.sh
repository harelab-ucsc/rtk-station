#!/bin/bash
# Install netplan configuration for the RTK base station Pi.
# Copies netplan/rtk.yaml to /etc/netplan/ and applies it when networkd is running.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NETPLAN_SRC="$SCRIPT_DIR/netplan/rtk.yaml"
NETPLAN_DEST="/etc/netplan/50-oasis-rtk.yaml"

if [ ! -f "$NETPLAN_SRC" ]; then
    echo "Error: netplan config not found at $NETPLAN_SRC"
    exit 1
fi

echo "Installing netplan config to $NETPLAN_DEST..."
sudo mkdir -p /etc/netplan
sudo cp "$NETPLAN_SRC" "$NETPLAN_DEST"
sudo chmod 600 "$NETPLAN_DEST"
echo "Installed $NETPLAN_DEST"

if pidof systemd > /dev/null 2>&1; then
    echo "Applying netplan config..."
    sudo netplan apply
    echo "Netplan applied."
else
    echo "systemd not active — netplan config installed, skipping netplan apply"
fi

HOSTNAME="pi-rtkbase"
echo "Setting hostname to $HOSTNAME..."
sudo hostnamectl set-hostname "$HOSTNAME"

# Ensure /etc/hosts has the canonical entry (127.0.1.1 is the Debian/Ubuntu
# convention for the machine's own hostname when it has no static loopback IP).
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi
echo "Hostname set."

echo "Done."
