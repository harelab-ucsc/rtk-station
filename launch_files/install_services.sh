#!/bin/bash
# Copy, enable and prepare RTK station .service files.
# Safe to run inside Docker (no active systemd): installs files but skips daemon-reload/enable.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVICE_DIR="$SCRIPT_DIR"
DEST_DIR="/etc/systemd/system"

echo "Installing dependencies..."
if curl -s --max-time 5 http://archive.raspberrypi.com > /dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y tmux python3-pip avahi-daemon
    sudo pip3 install --break-system-packages pygnssutils
else
    echo "WARNING: No internet — skipping apt/pip installs."
    echo "         Run manually when online: sudo apt-get install -y tmux python3-pip && sudo pip3 install --break-system-packages pygnssutils"
fi

echo "Copying service files from $SERVICE_DIR to $DEST_DIR..."

if [ ! -d "$SERVICE_DIR" ]; then
    echo "Error: $SERVICE_DIR does not exist."
    exit 1
fi

sudo mkdir -p "$DEST_DIR"
sudo cp "$SERVICE_DIR"/*.service "$DEST_DIR"/

echo "Installing helper scripts to /usr/local/bin/..."
for script in rtk-log-setup rtk-log-run rtk-log-tail rtk-watchdog; do
    sudo cp "$SCRIPT_DIR/$script" /usr/local/bin/$script
    sudo chmod +x /usr/local/bin/$script
done
sudo mkdir -p /var/log/rtk-station

if pidof systemd > /dev/null 2>&1; then
    echo "Reloading systemd daemon..."
    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload

    echo "Enabling all copied services to start on boot..."
    for file in "$SERVICE_DIR"/*.service; do
        [ -e "$file" ] || continue
        service_name=$(basename "$file")
        sudo systemctl enable "$service_name"
        echo "Enabled $service_name"
    done
else
    echo "systemd not active — service files installed, skipping daemon-reload/enable"
fi

if pidof systemd > /dev/null 2>&1; then
    echo "Enabling avahi-daemon (mDNS)..."
    sudo systemctl enable avahi-daemon
    sudo systemctl start avahi-daemon
fi

if pidof systemd > /dev/null 2>&1; then
    echo "Enabling SSH..."
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo "SSH enabled."
fi

echo "Done. You can now start services with: systemctl start <service-name>, or start_services.sh"

echo ""
echo "Installing netconfig..."
bash "$SCRIPT_DIR/install_netconfig.sh"

echo ""
echo "Setting up WiFi AP..."
bash "$SCRIPT_DIR/install_wifi_ap.sh"

echo ""
echo "Configuring ZED GNSS module..."
bash "$SCRIPT_DIR/configure_zed.sh"
