# Operations Guide

Common day-to-day tasks for this Nix config.

## Converting from Homebrew

All packages are now managed through Nix. Here's how to convert common brew patterns:

### Brew Formula (CLI Tool)

```nix
# brew install bat        → modules/home/packages/bat.nix
{ pkgs, ... }: {
  home.packages = [ pkgs.bat ];
}

# brew install ripgrep    → modules/home/packages/ripgrep.nix
{ config, ... }: {
  programs.ripgrep = {
    enable = true;
    arguments = [ "--smart-case" ];
  };
}
```

Check if a home-manager module exists (`programs.<name>.enable`) before falling back to `home.packages`.

### Brew Cask (GUI App)

```nix
# brew install --cask firefox    → modules/home/packages/firefox.nix
{ pkgs, ... }: {
  home.packages = [ pkgs.firefox ];
}

# brew install --cask discord    → modules/home/packages/discord.nix
_: {
  programs.discord.enable = true;
}

# brew install --cask whatsapp   → modules/home/packages/whatsapp.nix
{ pkgs, ... }: {
  home.packages = with pkgs; [ whatsapp-for-mac ];
}
```

Search `https://search.nixos.org/packages` for the Nix package name — it often differs from the cask name.

### Not in nixpkgs?

Create a custom derivation in `pkgs/custom/<name>.nix`:

```nix
{ pkgs, lib, ... }:
pkgs.stdenv.mkDerivation {
  name = "my-app";
  src = pkgs.fetchurl {
    url = "https://example.com/app.dmg";
    hash = "sha256-...";
  };
  installPhase = ''
    mkdir -p $out/Applications
    cp -r *.app $out/Applications/
  '';
}
```

Then reference as `pkgs.custom.<name>` in a package module.

### Steps

1. Create `modules/home/packages/<name>.nix` with the config
2. Add `../packages/<name>.nix` to the appropriate profile in `modules/home/profiles/<category>.nix`
3. Run `just rebuild <hostname>`

Profiles: `cli`, `shell`, `git`, `editors`, `security`, `macos`, `ai`.

## Add a Custom Package

Two steps:

1. Create the derivation in `pkgs/custom/<name>.nix` (e.g. fetch from GitHub or wrap a script)
2. It's auto-discovered — reference as `pkgs.custom.<name>` anywhere

If referencing a script in `scripts/`, use path `../../scripts/<file>.sh` (from `pkgs/custom/`).

## Add a New Host

1. Add entry to `hosts/default.nix` — required fields: `system`, `username`, `useremail`, `hostname`, `githubuser`, `githubname`, `gpgkeyid`, `type` (`"darwin"` / `"nixos"` / `"home-manager"`), `homeProfiles`.
2. If `type = "darwin"`: create `profiles/darwin/<hostname>.nix` with `{ ... }: { }`
3. If `type = "nixos"`: create `profiles/nixos/<name>.nix` and set `nixosProfile = "<name>"` in the host entry
4. Run `just rebuild <hostname>`

## Add a New Darwin Module

Create `modules/darwin/<name>.nix`:

```nix
{ pkgs, config, lib, ... }: {
  # options and config here
};
```

Add to the module list in `lib/default.nix` → `mkDarwinSystem` → `modules` list.

If the module needs per-host config values, add the field to `hosts/default.nix` and pass it via `specialArgs`.

## Add a Flake Input

1. Add to `inputs` in `flake.nix`
2. Access as `inputs.<name>` anywhere
3. If needed as a `specialArg` in `lib/default.nix`, add it to `baseSpecialArgs` or the individual builder's `specialArgs`

## Update Everything

```sh
just update       # nix flake update + optional determinate-nixd upgrade
```

## Format & Check

```sh
just fmt          # nix fmt (treefmt)
just check        # nix flake check
```

## Verify Before Rebuilding

Quick eval check without building:

```sh
nix eval '.#darwinConfigurations.<hostname>.system' --impure --no-write-lock-file
```

For NixOS:

```sh
nix eval '.#nixosConfigurations.<hostname>.system' --impure --no-write-lock-file
```

For home-manager standalone:

```sh
nix eval '.#homeConfigurations.<hostname>.home.activationPackage' --impure --no-write-lock-file
```

## Common Errors

**`access to absolute path '/etc/nixos/configuration.nix' is forbidden in pure evaluation mode`**
→ NixOS configs need `--impure` at build time. Normal.

**`path '/nix/store/scripts/...' does not exist`**
→ Wrong relative path in `pkgs/custom/*.nix`. From `pkgs/custom/`, use `../../scripts/<file>.sh`.

**`Could not write domain /Library/Preferences/SystemConfiguration/com.apple.smb.server`**
→ Remove `system.defaults.smb.NetBIOSName` — plist doesn't exist on newer macOS until SMB sharing is enabled.

## Directory Reference

| Path                          | Purpose                           |
| ----------------------------- | --------------------------------- |
| `hosts/default.nix`           | All per-host values               |
| `modules/darwin/*.nix`        | Darwin system configs             |
| `modules/home/packages/*.nix` | Program configs (one per file)    |
| `modules/home/profiles/*.nix` | Category groups (import packages) |
| `profiles/darwin/*.nix`       | Per-host darwin overrides         |
| `pkgs/custom/*.nix`           | Custom derivations                |
| `pkgs/overrides.nix`          | Package version overrides         |
| `scripts/*.sh`                | Shell scripts                     |
