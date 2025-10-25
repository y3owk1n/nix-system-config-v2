#!/bin/bash

focused_ws="$1"

# Find Picture-in-Picture window ID
pip_id=$(aerospace list-windows --all | awk -F'|' '/Picture-in-Picture/ {print $1}' | xargs)

if [ -n "$pip_id" ]; then
  aerospace move-node-to-workspace --window-id "$pip_id" "$focused_ws"
fi
