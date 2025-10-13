#!/usr/bin/env bash
set -euo pipefail

# Description: Select and run an Atuin script using fzf
# Requirements: atuin, grep, awk, fzf

# Get the list of available scripts
scripts=$(atuin scripts list | grep '^- ' | awk '{print $2}')

# If there are no scripts, exit gracefully
if [[ -z "$scripts" ]]; then
  echo "⚠️  No Atuin scripts found."
  exit 0
fi

# Use fzf to select one
selected=$(echo "$scripts" | fzf --prompt="Select a script: " --height=15 --reverse)

# Exit if nothing selected
if [[ -z "$selected" ]]; then
  echo "❌ No script selected."
  exit 0
fi

# Run the selected script
echo "🚀 Running: $selected"
atuin scripts run "$selected"
