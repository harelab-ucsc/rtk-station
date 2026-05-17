#!/bin/bash
# Install netplan configuration for the RTK portable bucket Pi.
# Copies netplan/rtk.yaml to /etc/netplan/ and applies it when networkd is running.

# Fix sudo hostname resolution before any sudo commands run.
# If the current hostname isn't in /etc/hosts, sudo warns on every call.
CURRENT_HOST=$(hostname)
if ! grep -qF "$CURRENT_HOST" /etc/hosts; then
    echo -e "127.0.1.1\t$CURRENT_HOST" | sudo tee -a /etc/hosts > /dev/null
fi

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
    # Ensure NetworkManager is running before applying — this Pi uses NM not networkd.
    sudo systemctl start NetworkManager 2>/dev/null || true
    sudo netplan apply
    echo "Netplan applied."
else
    echo "systemd not active — netplan config installed, skipping netplan apply"
fi

HOSTNAME="pi-rtkbucket"
echo "Setting hostname to $HOSTNAME..."

# Update /etc/hosts before calling hostnamectl so sudo can resolve the new
# hostname immediately on subsequent commands.
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" /etc/hosts
else
    echo -e "127.0.1.1\t$HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
fi

sudo hostnamectl set-hostname "$HOSTNAME"
echo "Hostname set."

echo "Done."
