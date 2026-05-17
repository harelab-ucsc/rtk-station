#!/bin/bash
# Configure the ZED GNSS module for RTK base station mode.
# Stops gnss_server if running to free /dev/ttyACM0, runs zed-config, then restarts.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WAS_RUNNING=false

if pidof systemd > /dev/null 2>&1 && systemctl is-active --quiet gnss_server; then
    echo "Stopping gnss_server to free /dev/ttyACM0..."
    sudo systemctl stop gnss_server
    WAS_RUNNING=true
    sleep 1
fi

python3 "$SCRIPT_DIR/zed-config"
STATUS=$?

if $WAS_RUNNING; then
    echo "Restarting gnss_server..."
    sudo systemctl start gnss_server
fi

exit $STATUS
