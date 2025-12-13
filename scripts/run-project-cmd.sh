#!/usr/bin/env bash

# ============================================================================
# Project Command Runner
# ============================================================================
# Interactive command runner that detects available project commands from:
# - package.json scripts (npm/yarn)
# - Justfile recipes
# - Makefile targets
#
# Uses fzf for interactive selection.

set -euo pipefail

# ============================================================================
# Command Collection
# ============================================================================
commands=()

# Detect and parse commands from package.json (Node project)
if [[ -f "package.json" ]]; then
  mapfile -t npm_scripts < <(jq -r '.scripts | keys[]' package.json 2>/dev/null)
  for script in "${npm_scripts[@]}"; do
    commands+=("npm run $script")
  done
fi

# Detect and parse commands from Justfile (Just task runner)
if [[ -f "Justfile" || -f "justfile" ]]; then
  for cmd in $(just --summary 2>/dev/null); do
    commands+=("just $cmd")
  done
fi

# Detect and parse Makefile targets
if [[ -f "Makefile" ]]; then
  mapfile -t make_targets < <(awk -F: '/^[a-zA-Z0-9][^$#\/\t=]*:/ {print $1}' Makefile | sort -u)
  for target in "${make_targets[@]}"; do
    commands+=("make $target")
  done
fi

# Add more project types here (e.g., poetry, rake, etc.)

# ============================================================================
# Command Execution
# ============================================================================

# If no commands were found, exit
if [[ ${#commands[@]} -eq 0 ]]; then
  echo "No recognizable project commands found in this directory."
  exit 1
fi

# Use fzf to select a command interactively
selected_command=$(printf '%s\n' "${commands[@]}" | fzf --preview= --prompt="Run command: ")

# Execute the selected command
if [[ -n $selected_command ]]; then
  echo "Running: $selected_command"
  eval "$selected_command"
else
  echo "No command selected."
fi
