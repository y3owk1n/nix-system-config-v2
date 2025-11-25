#!/bin/bash

# This script is to move the Picture-in-Picture window to the focused workspace, mostly for Firefox.
# This script is now not be used in the config, but let's keep it here just in case future me needs it.
# The rest of the references are all removed (search for `mptw` to get back these references in Github)

focused_ws="$1"

# Find Picture-in-Picture window ID
pip_id=$(aerospace list-windows --all | awk -F'|' '/Picture-in-Picture/ {print $1}' | xargs)

if [ -n "$pip_id" ]; then
  aerospace move-node-to-workspace --window-id "$pip_id" "$focused_ws"
fi
