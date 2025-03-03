# My Personal Nix System Configuration

This is a project to help me to manage my Nix system configuration, mainly with Darwin and Home Manager.

> Best effort to try to use as many built-in features as possible instead of relying third party software, e.g. Raycast, Aerospace, Yabai

## What do I use?

### General

- Shell: [fish](https://fishshell.com/)
- Terminal: [ghostty](https://ghostty.org/)
- Editor: [neovim](https://neovim.io/)
- Multiplexer: [tmux](https://github.com/tmux/tmux/wiki)
- Prompt: [starship](https://starship.rs/)
- Browser: Safari
- Docker: [orbstack](https://orbstack.dev/)
- Network: [tailscale](https://tailscale.com/)
- Launcher: Built-in Spotlight Search
- Window Tiling Manager: ~~[aerospace](https://nikitabobko.github.io/AeroSpace/guide)~~ MacOS Bulit-ins
  - Changing spaces with built-in macos commands with reduced motion
  - Managing windows with built-in macos commands
    - Left | Right | Top | Bottom | Fill
- Automation: [hammerspoon](https://www.hammerspoon.org/)
  - Best effort of vimium implementation [code here](https://github.com/y3owk1n/nix-system-config-v2/blob/main/config/hammerspoon/vimium.lua)
  - Menubar to show current space [code here](https://github.com/y3owk1n/nix-system-config-v2/blob/main/config/hammerspoon/menubar-space.lua)
  - Moving window to spaces [code here](https://github.com/y3owk1n/nix-system-config-v2/blob/main/config/hammerspoon/window.lua)

## Notes for future me

## Commands to make it work (For future me)

### Installing Nix on Macos

<https://nixos.org/download#nix-install-macos>

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### Configure github helper

### Getting localhostname

```bash
scutil --get LocalHostName
```

### Getting username

```bash
whoami
```

### Switch to fish shell

```bash
chsh -s (which fish)
```

### Build nix to results

#### Prebuilt script

The following script will initialise the function above and install additional node packages too.

```bash
bash ~/nix-system-config-v2/scripts/init.sh
```

#### Manually

```bash
// run this at the root of this directory
nix run nix-darwin -- switch --flake ~/nix-system-config-v2/.#Kyles-MacBook-Air
```

### Initialise darwin rebuild

```bash
darwin-rebuild switch --flake ~/nix-system-config-v2
```

### Cert SSL Issue

```bash
// https://github.com/NixOS/nix/issues/2899#issuecomment-1669501326
sudo rm /etc/ssl/certs/ca-certificates.crt
sudo ln -s /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
```

```

### Cleanup

```bash
// Cleanup nix
bash ~/nix-system-config-v2/scripts/nix-cleanup.sh

// Cleanup neovim
bash ~/nix-system-config-v2/scripts/nvim-reset.sh
```

### Check config issue

```bash
nix config check
```

If there's multiple nix in the path, it is from the nix root, run the following the remove it.

```bash
sudo -i nix-env -e nix
```

### error: file 'nixpkgs' was not found in the Nix search path (add it using $NIX_PATH or -I)

```bash
// https://github.com/NixOS/nix/issues/2982#issuecomment-539794642
sudo -i nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
sudo -i nix-channel --update nixpkgs
```

### Installing NPM packages that are not available in Nix

#### Prebuilt sript

```bash
bash ~/nix-system-config-v2/scripts/install-node-packages.sh
```

#### Manually

Navigate to `...../modules/home-manager/node-packages` and run the following command to generate a nix expression. The expression can then be added into home manager

- `-18` is to build with nodejs v18

```bash
nix-shell -p nodePackages.node2nix --command "node2nix -18 -i ./node-packages.json -o node"
```

### Karabiner Driverkit

```bash
https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v3.1.0/Karabiner-DriverKit-VirtualHIDDevice-3.1.0.pkg
```

```bash
// Activate
/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
```

```bash
// Restart kanata
sudo launchctl unload /Library/LaunchDaemons/org.nixos.kanata.plist
sudo launchctl load /Library/LaunchDaemons/org.nixos.kanata.plist
```
