# Utility Scripts

This directory contains various utility scripts for system management and development.

## Scripts

### `init.sh`

Initializes a new Nix Darwin system for a given user.

```bash
./init.sh <username>
```

### `run-project-cmd.sh`

Interactive command runner that detects available project commands from:

- `package.json` scripts (npm/yarn)
- `Justfile` recipes
- `Makefile` targets

Uses `fzf` for interactive selection.

### `atuin-run-script.sh`

Helper script for Atuin shell history management.

### `nvim-reset.sh`

Resets Neovim configuration and cache.

### `passx.sh`

Extended pass (password manager) utilities.

### `move-pip-to-ws.sh`

Utility for managing Python pip installations.
