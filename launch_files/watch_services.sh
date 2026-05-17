#!/bin/bash
# Open a tmux session showing live logs for all RTK services.
# Reattaches if the session is already running.
#
# Layout:
#   ┌─────────────────────┬─────────────────────┐
#   │    gnss_server      │   gnss_to_ntrip     │
#   └─────────────────────┴─────────────────────┘

SESSION="rtk-station"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach-session -t "$SESSION"
    reset
    exit 0
fi

tmux new-session -d -s "$SESSION" -n logs "rtk-log-tail gnss_server"
tmux set-option -t "$SESSION" pane-border-status top
tmux set-option -t "$SESSION" pane-border-format " #{pane_title} "
tmux select-pane -t "$SESSION:0.0" -T "gnss_server"

tmux split-window -t "$SESSION:0.0" -h "rtk-log-tail gnss_to_ntrip"
tmux select-pane -t "$SESSION:0.1" -T "gnss_to_ntrip"

tmux select-pane -t "$SESSION:0.0"
tmux attach-session -t "$SESSION"
reset
