#!/bin/bash
# Configure the ZED GNSS module.
# Stops gnss_server to free /dev/rtk-zed, runs the config script, then restarts.
#
# Usage:
#   configure_zed.sh          — RTCM rates only (safe to re-run, no survey-in reset)
#   configure_zed.sh --init   — Full init: sets TMODE3=SURVEY_IN then RTCM rates.
#                               Only use on a fresh/reset ZED; resets any completed survey-in.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WAS_RUNNING=false

if pidof systemd > /dev/null 2>&1 && systemctl is-active --quiet gnss_server; then
    echo "Stopping gnss_server to free /dev/rtk-zed..."
    sudo systemctl stop gnss_server
    WAS_RUNNING=true
    sleep 1
fi

if [ "$1" = "--init" ]; then
    python3 "$SCRIPT_DIR/zed-config-init"
else
    python3 "$SCRIPT_DIR/zed-config"
fi
STATUS=$?

if $WAS_RUNNING; then
    echo "Restarting gnss_server..."
    sudo systemctl start gnss_server
fi

exit $STATUS
