#!/bin/bash
# Open a tmux session showing live logs for all three RTK services.
# Reattaches if the session is already running.
#
# Layout:
#   ┌─────────────────────┬─────────────────────┐
#   │                     │   gnss_to_ntrip     │
#   │    gnss_server      ├─────────────────────┤
#   │                     │   gnss_to_rfd900    │
#   └─────────────────────┴─────────────────────┘

SESSION="rtk-station"
LOG_BASE="/var/log/rtk-station"

# Build a command for each pane: polls until the log file appears then follows it.
pane_cmd() {
    local svc="$1"
    echo "bash -c 'echo Waiting for $svc log...; \
while true; do \
  f=\$(ls -1t $LOG_BASE/boot-*/$svc.log 2>/dev/null | head -1); \
  [ -n \"\$f\" ] && exec tail -F \"\$f\"; \
  sleep 2; \
done'"
}

if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach-session -t "$SESSION"
    reset
    exit 0
fi

tmux new-session -d -s "$SESSION" -n logs

# Show pane titles at the top of each border
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "

# Pane 0 — gnss_server (left half)
tmux select-pane -t "$SESSION:0.0" -T "gnss_server"
tmux send-keys -t "$SESSION:0.0" "$(pane_cmd gnss_server)" Enter

# Pane 1 — gnss_to_ntrip (top right)
tmux split-window -t "$SESSION:0.0" -h
tmux select-pane -t "$SESSION:0.1" -T "gnss_to_ntrip"
tmux send-keys -t "$SESSION:0.1" "$(pane_cmd gnss_to_ntrip)" Enter

# Pane 2 — gnss_to_rfd900 (bottom right)
tmux split-window -t "$SESSION:0.1" -v
tmux select-pane -t "$SESSION:0.2" -T "gnss_to_rfd900"
tmux send-keys -t "$SESSION:0.2" "$(pane_cmd gnss_to_rfd900)" Enter

tmux select-pane -t "$SESSION:0.0"
tmux attach-session -t "$SESSION"
reset
