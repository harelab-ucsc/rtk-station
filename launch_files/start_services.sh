#!/bin/bash
# Start RTK base station systemd services.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if pidof systemd > /dev/null 2>&1; then
    for service_file in "$SCRIPT_DIR"/*.service; do
        [ -e "$service_file" ] || continue
        echo "Starting $(basename "$service_file")..."
        sudo systemctl start "$(basename "$service_file")"
    done
else
    echo "systemd not active — cannot start services"
    exit 1
fi
