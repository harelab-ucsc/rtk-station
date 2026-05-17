#!/bin/bash
# Configure the HARELab-RTK-Bucket WiFi access point.
# Netplan manages the AP via wpa_supplicant (no separate hostapd needed).
# dnsmasq serves DHCP to clients on wlan0.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Installing dnsmasq..."
if curl -s --max-time 5 http://archive.raspberrypi.com > /dev/null 2>&1; then
    sudo apt-get install -y dnsmasq wpasupplicant
else
    echo "WARNING: No internet — skipping apt install. Run manually: sudo apt-get install -y dnsmasq wpasupplicant"
fi

echo "Installing dnsmasq config..."
sudo cp "$SCRIPT_DIR/dnsmasq-rtk.conf" /etc/dnsmasq.d/rtk-ap.conf

# Remove the networkd wlan0 config from the previous attempt if present
sudo rm -f /etc/systemd/network/10-wlan0.network

# Remove stale hostapd if it was installed previously
if systemctl is-enabled hostapd 2>/dev/null | grep -q enabled; then
    echo "Disabling hostapd (netplan now manages the AP)..."
    sudo systemctl disable --now hostapd 2>/dev/null || true
fi

if pidof systemd > /dev/null 2>&1; then
    echo "Applying netplan and restarting dnsmasq..."
    sudo netplan apply
    sudo systemctl enable dnsmasq
    sudo systemctl restart dnsmasq
    echo "Done."
else
    echo "systemd not active — configs installed, skipping apply"
fi

echo "WiFi AP setup done. SSID: HARELab-RTK-Bucket, password: password, IP: 172.31.106.2"
