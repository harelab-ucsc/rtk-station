#!/bin/bash
# Stop RTK base station systemd services.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if pidof systemd > /dev/null 2>&1; then
    for service_file in "$SCRIPT_DIR"/*.service; do
        [ -e "$service_file" ] || continue
        echo "Stopping $(basename "$service_file")..."
        sudo systemctl stop "$(basename "$service_file")"
    done
else
    echo "systemd not active — cannot stop services"
fi
