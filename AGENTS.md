# Nix System Configuration — AI Agent Guide

## Architecture

```
flake.nix                 ← Entry point (flake-parts based)
├── lib/                  ← Builder functions & flake-parts modules
│   ├── default.nix       ← mkDarwinSystem, mkNixosSystem, mkHomeConfiguration
│   ├── systems.nix       ← Supported system list
│   ├── treefmt.nix       ← Code formatting config
│   ├── pre-commit.nix    ← Git hooks
│   └── devshell.nix      ← Development shell
├── hosts/
│   └── default.nix       ← Centralized host metadata (single source of truth)
├── modules/
│   ├── darwin/           ← nix-darwin system modules
│   ├── nixos/            ← NixOS system modules
│   ├── home/             ← Home-manager modules
│   │   ├── base.nix      ← HM base (home dir, aliases, stateVersion)
│   │   ├── profiles/     ← Feature profiles (import package groups)
│   │   └── packages/     ← Individual program configs (one file per program)
│   └── stylix/           ← Theming module
├── pkgs/                 ← Custom packages & overrides
├── profiles/             ← Per-host profiles
│   ├── darwin/
│   └── nixos/
├── config/               ← Static dotfiles (symlinked, not managed by Nix)
└── scripts/              ← Shell scripts
```

## Key Design Principles

1. **Data-driven hosts** — All per-host values in `hosts/default.nix`. Adding a new host means adding one entry there and one profile in `profiles/<type>/`.
2. **No thin aggregation layers** — `modules/home/profiles/*.nix` group packages by category but with `imports = [...]`. No `lib.mkEnableOption` wrappers — just direct imports.
3. **Proper Nix module system** — All darwin/NixOS modules use standard module args (`{ pkgs, config, lib, ... }`), not `import` function patterns.
4. **Consistent package pattern** — Each program gets one file in `modules/home/packages/`. Files use destructured module args.

## Adding a New Host

1. Add entry to `hosts/default.nix` with all required fields.
2. Create profile in `profiles/darwin/<hostname>.nix` or `profiles/nixos/<name>.nix`.
3. Run `just rebuild <hostname>`.

## Adding a New Package

1. Create `modules/home/packages/<name>.nix` with the program config.
2. Add it to the appropriate profile in `modules/home/profiles/<category>.nix`.

## Converting from Homebrew

When asked to convert a brew install to Nix:

- **CLI tool (formula)** → `home.packages = [ pkgs.<name> ]` or `programs.<name>.enable = true` if a home-manager module exists.
- **GUI app (cask)** → Same patterns, but check `https://search.nixos.org/packages` first — the Nix name often differs (e.g. `whatsapp-for-mac` not `whatsapp`).
- **Not in nixpkgs** → Create a custom derivation in `pkgs/custom/<name>.nix` using `pkgs.fetchurl` or `pkgs.fetchzip`, then reference as `pkgs.custom.<name>`.
- Always prefer `programs.<name>.enable` over `home.packages` when a home-manager module exists (gives config management).
- Package modules go in `modules/home/packages/<name>.nix`, imported via `modules/home/profiles/<category>.nix`.

## Key Commands

- `just rebuild <host>` — Rebuild nix-darwin/NixOS
- `just update` — Update flake inputs
- `just fmt` — Format all files
- `just check` — Run flake checks
- `just dev` — Enter dev shell
- `just gc` — Clean up generations and garbage collect
