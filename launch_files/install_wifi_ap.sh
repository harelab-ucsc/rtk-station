#!/bin/bash
# Configure the HARELab-RTK-Bucket WiFi access point.
# NetworkManager handles the AP natively — no hostapd needed.
# dnsmasq serves DHCP to clients on wlan0.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Installing dnsmasq..."
if curl -s --max-time 5 http://archive.raspberrypi.com > /dev/null 2>&1; then
    sudo apt-get install -y dnsmasq
else
    echo "WARNING: No internet — skipping apt install. Run manually: sudo apt-get install -y dnsmasq"
fi

echo "Installing dnsmasq config..."
sudo cp "$SCRIPT_DIR/dnsmasq-rtk.conf" /etc/dnsmasq.d/rtk-ap.conf

# Disable hostapd if it was installed from a previous attempt
if systemctl is-enabled hostapd 2>/dev/null | grep -q enabled; then
    echo "Disabling hostapd (NetworkManager now manages the AP)..."
    sudo systemctl disable --now hostapd 2>/dev/null || true
fi

# Remove stale networkd wlan0 config from a previous attempt
sudo rm -f /etc/systemd/network/10-wlan0.network

if pidof systemd > /dev/null 2>&1; then
    echo "Applying netplan..."
    sudo netplan generate
    sudo netplan apply || true
    sudo systemctl enable dnsmasq
    sudo systemctl restart dnsmasq
    echo "Done."
else
    echo "systemd not active — configs installed, skipping apply"
fi

echo "WiFi AP setup done. SSID: HARELab-RTK-Bucket, password: password, IP: 172.31.106.2"
