# Nix System Configuration — AI Agent Guide

## Architecture

```
flake.nix                 ← Entry point (flake-parts)
├── lib/default.nix       ← mkDarwinSystem, mkNixosSystem, mkHomeConfiguration
├── hosts/default.nix     ← Per-host metadata (single source of truth)
├── modules/
│   ├── darwin/           ← macOS system modules
│   ├── nixos/            ← NixOS system modules
│   ├── home/
│   │   ├── base.nix      ← HM base (home dir, aliases, stateVersion)
│   │   ├── profiles/     ← Feature profiles (import package groups)
│   │   └── packages/     ← One file per program
│   └── stylix/           ← Theming
├── pkgs/custom/          ← Custom derivations (fetchurl, fetchzip)
├── profiles/
│   ├── darwin/           ← Per-host darwin overrides
│   └── nixos/            ← Per-host nixos overrides
├── skills/               ← Local agent skills (SKILL.md per directory)
├── config/               ← Static dotfiles (symlinked, not Nix-managed)
└── scripts/              ← Shell utilities
```

## How to add things

### New host

1. Add entry to `hosts/default.nix` — fields: `system`, `username`, `useremail`, `hostname`, `githubuser`, `githubname`, `gpgkeyid`, `type`, `homeProfiles`.
2. Create `profiles/darwin/<hostname>.nix` or `profiles/nixos/<name>.nix`.
3. `just rebuild <hostname>`

### New package

1. Create `modules/home/packages/<name>.nix`:
   ```nix
   { pkgs, ... }: {
     programs.<name>.enable = true;  # prefer if module exists
     # or: home.packages = [ pkgs.<name> ];
   }
   ```
2. Add `../packages/<name>.nix` to the profile in `modules/home/profiles/<category>.nix`.
3. `just rebuild <hostname>`

Profiles: `cli`, `shell`, `git`, `editors`, `security`, `macos`, `ai`.

### Custom derivation (not in nixpkgs)

1. Create `pkgs/custom/<name>.nix` using `pkgs.fetchurl` or `pkgs.fetchzip`.
2. Reference as `pkgs.custom.<name>` — auto-discovered.

### New darwin module

1. Create `modules/darwin/<name>.nix` with `{ pkgs, config, lib, ... }: { ... }`.
2. Add to `modules` list in `lib/default.nix` → `mkDarwinSystem`.
3. If per-host config needed, add field to `hosts/default.nix` and pass via `specialArgs`.

### New flake input

1. Add to `inputs` in `flake.nix`.
2. Access as `inputs.<name>`.
3. If needed in `specialArgs`, add to `baseSpecialArgs` in `lib/default.nix`.

## Adding agent skills

Skills live in `skills/<name>/SKILL.md`. The `local` source is pre-configured.

1. Create `skills/<name>/SKILL.md` with frontmatter:
   ```markdown
   ---
   name: <name>
   description: "<what it does and when>"
   ---
   ```
2. Add `"<name>"` to `skills.enable` in `modules/home/packages/skills.nix`.
3. `just rebuild`

For external skills, see `skills/add-skill/SKILL.md`.

## Key commands

```bash
just rebuild <host>   # Rebuild system
just update           # Update flake inputs
just fmt              # Format (treefmt)
just check            # Flake checks
just dev              # Dev shell
just gc               # Garbage collect
```

## Verification

Before rebuilding, eval to catch errors:

```bash
nix eval '.#darwinConfigurations.<host>.system' --impure
nix eval '.#nixosConfigurations.<host>.system' --impure
```

## Design principles

- **Data-driven hosts** — all per-host values in `hosts/default.nix`.
- **One file per program** — `modules/home/packages/<name>.nix`.
- **Profiles group packages** — `modules/home/profiles/<category>.nix` with `imports = [...]`.
- **Standard module args** — `{ pkgs, config, lib, ... }`, not `import` function patterns.

## Converting from Homebrew

See `DOCS.md` for detailed examples. Summary:

- CLI formula → `programs.<name>.enable = true` or `home.packages = [ pkgs.<name> ]`
- GUI cask → same, but search `https://search.nixos.org/packages` for the Nix name
- Not in nixpkgs → `pkgs/custom/<name>.nix` with `fetchurl`/`fetchzip`
