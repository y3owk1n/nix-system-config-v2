# Operations Guide

Day-to-day tasks. For architecture and "how to add things", see `AGENTS.md`.

## Converting from Homebrew

### CLI tool (formula)

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

Prefer `programs.<name>.enable` when a home-manager module exists.

### GUI app (cask)

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

Search `https://search.nixos.org/packages` — the Nix name often differs from the cask name.

### Not in nixpkgs

Create `pkgs/custom/<name>.nix`:

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

Reference as `pkgs.custom.<name>` in a package module.

## Custom derivation patterns

### Rust package override

```nix
(pkgs.FOO.overrideAttrs (finalAttrs: prevAttrs: {
  cargoHash = "";  # build once, replace with hash
  src = pkgs.fetchBAR { ... };
  version = "...";
  cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
    inherit (finalAttrs) pname src version;
    hash = finalAttrs.cargoHash;
  };
}))
```

### Script from scripts/ directory

In `pkgs/custom/<name>.nix`:

```nix
{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "my-script";
  runtimeInputs = [ pkgs.coreutils ];
  text = builtins.readFile ../../scripts/my-script.sh;
}
```

## Common errors

| Error                                                   | Fix                                                                                                                     |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `access to absolute path '/etc/nixos/...' is forbidden` | Add `--impure` — normal for NixOS                                                                                       |
| `path '/nix/store/scripts/...' does not exist`          | Wrong relative path in `pkgs/custom/`. Use `../../scripts/<file>.sh`                                                    |
| `Could not write domain ...com.apple.smb.server`        | Remove `system.defaults.smb.NetBIOSName` — plist doesn't exist until SMB sharing is enabled                             |
| `file 'nixpkgs' was not found`                          | `sudo -i nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && sudo -i nix-channel --update nixpkgs` |

## SSL certificate fix

```bash
sudo rm /etc/ssl/certs/ca-certificates.crt
sudo ln -s /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
```

## Spotlight indexing for Nix apps

Nix-darwin links apps to `/Applications` directly. If you need Spotlight to find them, see the `home.activation.copyNixApps` pattern in `NOTES.md`.

## LaunchAgent management

```bash
# List services
launchctl list | grep -i <name>

# Kill a service
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/<name>.plist

# Start a service
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<name>.plist

# Remove dead plist
rm ~/Library/LaunchAgents/<name>.plist
```

## Atuin daemon fix

```bash
pkill -9 atuin
rm ~/.local/share/atuin/daemon.sock
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.atuin-daemon
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.atuin-daemon.plist
```

## Root fish shell

```bash
dscl . -read /Users/root UserShell
sudo chsh -s /etc/profiles/per-user/kylewong/bin/fish root
```

## GPG backup

```bash
gpg --list-secret-keys --keyid-format LONG
# use the key after rsa4096 as input
```

## Pass (secret manager)

Multi-machine setup:

1. Each machine has its own private key
2. Exchange public keys between machines
3. `pass init <pubkey-a> <pubkey-b>`
4. Trust the other key: `pass --edit-key <pubkey> → trust → 5 → quit`

Key rotation: init with new keys first, verify access, then delete old keys.

## OrbStack Docker in NixOS

```bash
mac link docker
```

See: https://github.com/orbstack/orbstack/issues/269#issuecomment-1548858675

## Directory reference

| Path                               | Purpose                           |
| ---------------------------------- | --------------------------------- |
| `hosts/default.nix`                | All per-host values               |
| `modules/darwin/*.nix`             | macOS system configs              |
| `modules/home/packages/*.nix`      | Program configs (one per file)    |
| `modules/home/profiles/*.nix`      | Category groups (import packages) |
| `modules/home/packages/skills.nix` | Agent skills configuration        |
| `profiles/darwin/*.nix`            | Per-host darwin overrides         |
| `pkgs/custom/*.nix`                | Custom derivations                |
| `skills/*/SKILL.md`                | Local agent skills                |
