#!/usr/bin/env bash

# https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer

# Ensure we have a selected project
if [[ $# -eq 1 ]]; then
	selected=$1
else
	selected=$(
		(
			echo ~/nix-system-config-v2
			echo ~/Library/Mobile Documents/com~apple~CloudDocs/Cloud Notes
			find ~/Dev -mindepth 1 -maxdepth 1 -type d
		) | fzf
	)
fi

# Exit if no selection was made
if [[ -z $selected ]]; then
	exit 0
fi

# Create a safe session name (replace dots with underscores)
selected_name=$(basename "$selected" | tr . _)

# Check if tmux is running
tmux_running=$(pgrep tmux)

# If not in a tmux session and no tmux is running, create a new session
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
	tmux new-session -A -s "$selected_name" -c "$selected"
	exit 0
fi

# Create the session if it doesn't exist
if ! tmux has-session -t="$selected_name" 2>/dev/null; then
	tmux new-session -ds "$selected_name" -c "$selected"
fi

# Switch to the session
if [[ -z $TMUX ]]; then
	# If we're not in a tmux session, attach to the new/existing session
	tmux attach-session -t "$selected_name"
else
	# If we're already in a tmux session, switch client
	tmux switch-client -t "$selected_name"
fi
