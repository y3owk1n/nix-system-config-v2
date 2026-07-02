# Operations Guide

Common day-to-day tasks for this Nix config.

## Add a CLI Program

Create `modules/home/packages/<name>.nix`:

```nix
_: {
  programs.<name>.enable = true;
  # or home.packages = [ pkgs.<name> ];
}
```

Add it to the right profile in `modules/home/profiles/<category>.nix`:

```nix
../packages/<name>.nix
```

Profiles: `cli`, `shell`, `git`, `editors`, `security`, `macos`, `ai`.

## Add a Homebrew Cask

Add to `homebrew.casks` in the host entry in `hosts/default.nix`:

```nix
homebrew.casks = [ "firefox" "discord" "new-cask" ];
```

## Add a Homebrew Formula

Same place — add to `homebrew.brews`:

```nix
homebrew.brews = [ "mole" "new-formula" ];
```

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
2. If using with nix-homebrew taps, use `flake = false`
3. Access as `inputs.<name>` anywhere
4. If needed as a `specialArg` in `lib/default.nix`, add it to `baseSpecialArgs` or the individual builder's `specialArgs`

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

**Homebrew tap permission error** (`could not create work tree dir`)
→ Tap key name doesn't match GitHub repo. Use `user/homebrew-repo` format, not `user/repo`.

**`The option 'nix-homebrew.user' was accessed but has no value`**
→ Missing `nix-homebrew.user = username;` in the nix-homebrew config.

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
