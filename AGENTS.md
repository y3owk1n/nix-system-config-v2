# AGENTS.md

This document provides guidance for AI agents working on this Nix system configuration repository.

## Project Overview

This is a **Nix flake-based system configuration** for managing macOS (via nix-darwin) and Linux (via NixOS) systems using flake-parts.

**Key Technologies:**

- Nix with flakes and flake-parts
- nix-darwin for macOS, NixOS for Linux
- Home Manager for cross-platform user environment
- Determinate Nix, nix-homebrew, stylix

## Build/Lint/Test Commands

```bash
# Rebuild system (macOS)
just rebuild [hostname]

# Rebuild system (Linux)
sudo nixos-rebuild switch --impure --flake .#[hostname]

# Format all code
just fmt

# Run checks
just check

# Enter dev shell
just dev

# Update flake inputs
just update

# Garbage collection
just gc

# Clean artifacts
just clean
```

### Single File Commands

```bash
# Check single Nix file
nix-instantiate --parse file.nix
nix eval --file file.nix

# Lint Nix file
deadnix file.nix
statix check file.nix

# Format file
nixfmt file.nix
treefmt --no-cache file
```

### Pre-commit Hooks

```bash
pre-commit run --all-files
pre-commit run deadnix
pre-commit run statix
pre-commit run treefmt
```

## Code Style Guidelines

### EditorConfig (`.editorconfig`)

- Indent: 2 spaces
- Line endings: LF
- Charset: UTF-8
- Max line length: 120
- Trailing whitespace trimmed
- Final newline required

### Nix Code

**Formatting:** Use `nixfmt`, 2-space indentation

```nix
{
  inputs,
  ...
}:
```

**Module Structure:**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.your-module;
in
{
  options = {
    your-module = {
      enable = lib.mkEnableOption "Description";
    };
  };
  config = lib.mkIf cfg.enable { };
}
```

**Naming:**

- Attributes: `kebab-case`
- Options: `camelCase`
- Modules: `kebab-case.nix`
- Error handling: `lib.mkIf`, `lib.mkMerge`

### Shell Scripts (`.sh`)

- Use `shfmt`
- POSIX compliant
- `#!/usr/bin/env bash`
- `set -euo pipefail`

### Lua Code

- Use `stylua`
- 2-space indentation

### Other Formats

- YAML: `yamlfmt` (2-space indent)
- TOML: `taplo`
- Markdown: `prettier` (MD025 disabled)
- JSON: `prettier`
- Justfile: `just --fmt`

## Directory Structure

```
├── config/              # App configs (nvim, kanata)
├── darwin/              # macOS modules & hosts
├── home-manager/        # User environment config
├── parts/               # Flake parts (hosts, overlays)
├── scripts/             # Utility scripts
├── flake.nix            # Main flake
├── Justfile             # Task runner
└── .editorconfig        # Editor config
```

## Import Organization

- `parts/*.nix` - Flake part configs
- `parts/overlays/*.nix` - Package overlays
- `parts/hosts/*.nix` - Host definitions
- `darwin/modules/*.nix` - System modules
- `darwin/shared/*.nix` - Shared darwin config
- `home-manager/shared/*.nix` - Shared HM config

## Common Tasks

### Adding a New Darwin Module

1. Create in `darwin/modules/` or `darwin/shared/`
2. Import in host's `modules` list in `parts/hosts/*.nix`
3. Format with `just fmt`

### Adding a New Homebrew Cask/Formula

1. Add input to `flake.nix`
2. Import via `darwin/shared/nix-homebrew.nix`
3. Add to `homebrew.bundle` list

### Updating Flake Inputs

```bash
just update
```

## Important Notes

- Run `just fmt` before committing
- Run `just check` before rebuilding
- Use `--impure` flag for local flake references
- Host configs in `parts/hosts/*.nix`
- Module imports use relative paths (e.g., `../../darwin/...`)
- Pre-commit hooks run automatically
- Test with `just rebuild <hostname>` before committing
