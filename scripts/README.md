# ============================================================================

# Utility Scripts

# ============================================================================

This directory contains various utility scripts for system management and development.
These scripts complement the Justfile commands and provide additional functionality.

## Scripts

### `init.sh`

**Purpose:** Initializes a new Nix Darwin system for a given user.

**Usage:**

```bash
./init.sh <username>
```

**What it does:**

- Finds the nix-system-config directory automatically
- Runs `nix-darwin` switch with proper flake path
- Sets up initial system configuration

### `run-project-cmd.sh`

**Purpose:** Interactive command runner that detects available project commands.

**Features:**

- Detects commands from `package.json` scripts (npm/yarn)
- Parses `Justfile` recipes
- Extracts `Makefile` targets
- Uses `fzf` for interactive selection

**Usage:**

```bash
./run-project-cmd.sh
```

### `passx.sh` (PassX)

**Purpose:** Advanced password store environment manager.

**Features:**

- Project-scoped secret management
- Multi-environment support (dev, staging, prod)
- Environment variable loading with merge strategies
- Interactive commands with fzf
- Secure backup/restore functionality
- Export/import to .env files

**Usage:**

```bash
# Add a secret
./passx.sh dev add API_KEY

# Run command with secrets loaded
./passx.sh dev run npm start

# List all environments
./passx.sh envs
```

### `atuin-run-script.sh`

**Purpose:** Helper script for Atuin shell history management.

**Usage:** Called by other scripts for Atuin integration.

### `nvim-reset.sh`

**Purpose:** Resets Neovim configuration and cache.

**Usage:**

```bash
./nvim-reset.sh
```

### `move-pip-to-ws.sh`

**Purpose:** Utility for managing Python pip installations in workspaces.

**Usage:** Internal utility for Python environment management.
