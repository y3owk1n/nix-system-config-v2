#!/usr/bin/env bash

# Tmux session manager with fuzzy finder integration
# Original inspiration: ThePrimeagen's tmux-sessionizer

set -eo pipefail

# Configuration --------------------------------------------------------------
declare -a config_static_paths=(
	"$HOME/nix-system-config-v2"
	"$HOME/nix-system-config-v2/config/nvim"
	"$HOME/Downloads"
)

declare -a config_dynamic_roots=(
	"$HOME/Dev"
)

# Constants -------------------------------------------------------------------
declare -r script_name="$(basename "$0")"
declare -r -a valid_dynamic_depth=(-mindepth 1 -maxdepth 1)

# Global variables -----------------------------------------------------------
declare -a choices=()
declare selected_path selected_name

# Colors ---------------------------------------------------------------------
declare -r color_tmux_icon=$'\e[38;2;237;135;150m' # catppuccin red
declare -r color_reset=$'\e[0m'

# Tmux configuration ---------------------------------------------------------
declare -r tmux_icon=""

# Functions -------------------------------------------------------------------
die() {
	echo "$script_name: $*" >&2
	exit 1
}

validate_directory() {
	[[ -d "$1" ]] || return 1
	return 0
}

get_session_name() {
	local path="$1"
	basename "$path" | tr . _
}

session_exists() {
	local session_name="$1"
	tmux has-session -t="$session_name" 2>/dev/null
}

add_choice() {
	local path="$1"
	local name=$(basename "$path")
	local session_name=$(get_session_name "$path")

	# Add annotation if session exists
	if session_exists "$session_name"; then
		name="${color_tmux_icon}${tmux_icon}${color_reset} ${name}"
	else
		name="  ${name}"
	fi

	choices+=("${name}"$'\t'"${path}")
}

process_static_paths() {
	for path in "${config_static_paths[@]}"; do
		validate_directory "$path" && add_choice "$path"
	done
}

process_dynamic_roots() {
	for root in "${config_dynamic_roots[@]}"; do
		validate_directory "$root" || continue

		while IFS= read -r -d '' dir; do
			add_choice "$dir"
		done < <(
			find "$root" \
				"${valid_dynamic_depth[@]}" \
				-type d \
				-print0 2>/dev/null
		)
	done
}

setup_fzf_preview() {
	export SHELL="$(command -v bash)"
	local preview_cmd='
        dir=$(echo -n {} | cut -d$'\''\t'\'' -f2)
        if [ -d "$dir" ]; then
            ls -1 "$dir" | head -n 100
        else
            bat --style=plain --color=always "$dir" 2>/dev/null || cat "$dir" 2>/dev/null
        fi
    '

	printf "%s\n" "${choices[@]}" | fzf \
		--ansi \
		--delimiter=$'\t' \
		--with-nth 1 \
		--preview "$preview_cmd"
}

validate_selection() {
	[[ -n "$selected_path" ]] || die "No path selected"
	validate_directory "$selected_path" || die "Invalid directory: $selected_path"
}

create_session_name() {
	selected_name="$(get_session_name "$selected_path")"
	[[ -n "$selected_name" ]] || die "Failed to create session name"
}

tmux_new_session() {
	tmux new-session -ds "$selected_name" -c "$selected_path"
}

tmux_attach_session() {
	if [[ -z "$TMUX" ]] && [[ -z "$(pgrep tmux)" ]]; then
		tmux new-session -A -s "$selected_name" -c "$selected_path"
	else
		tmux switch-client -t "$selected_name"
	fi
}

handle_tmux_session() {
	if ! tmux has-session -t="$selected_name" 2>/dev/null; then
		tmux_new_session
	fi

	tmux_attach_session
}

main() {
	# Handle arguments
	(($# > 0)) && die "This script does not accept arguments"

	# Populate choices
	process_static_paths
	process_dynamic_roots

	# Ensure we have choices
	((${#choices[@]} > 0)) || die "No valid directories found"

	# Get user selection
	local selection=$(setup_fzf_preview)
	[[ -n "$selection" ]] || exit 0

	# Extract path from selection
	selected_path="${selection#*$'\t'}"
	validate_selection

	# Prepare tmux session
	create_session_name
	handle_tmux_session
}

# Main execution -------------------------------------------------------------
main "$@"
