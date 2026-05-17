#!/bin/bash
# Install and configure the HARELAB-RTK WiFi access point.
# Uses hostapd for the AP and dnsmasq for DHCP on wlan0 (172.31.106.2/24).

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Installing hostapd and dnsmasq..."
if curl -s --max-time 5 http://archive.raspberrypi.com > /dev/null 2>&1; then
    sudo apt-get install -y hostapd dnsmasq
else
    echo "WARNING: No internet — skipping apt install. Run manually: sudo apt-get install -y hostapd dnsmasq"
fi

echo "Installing hostapd config..."
sudo cp "$SCRIPT_DIR/hostapd.conf" /etc/hostapd/hostapd.conf
sudo sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "Installing dnsmasq config..."
sudo cp "$SCRIPT_DIR/dnsmasq-rtk.conf" /etc/dnsmasq.d/rtk-ap.conf

# Assign static IP to wlan0 via systemd-networkd (bypasses netplan's
# access-points requirement for wifis entries).
echo "Configuring wlan0 static IP via systemd-networkd..."
sudo tee /etc/systemd/network/10-wlan0.network > /dev/null << 'EOF'
[Match]
Name=wlan0

[Network]
Address=172.31.106.2/24
EOF

if pidof systemd > /dev/null 2>&1; then
    sudo systemctl restart systemd-networkd
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl restart hostapd
    sudo systemctl enable dnsmasq
    sudo systemctl restart dnsmasq
    echo "hostapd and dnsmasq enabled."
else
    echo "systemd not active — configs installed, skipping enable/start"
fi

echo "WiFi AP setup done. SSID: HARELAB-RTK, password: password, IP: 172.31.106.2"
