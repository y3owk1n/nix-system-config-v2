# My Personal Nix System Configuration

This is a project to help me to manage my Nix system configuration, mainly with Darwin and Home Manager.

## What do I use?

### General

- Shell: [fish](https://fishshell.com/)
- Terminal: ~~[alacritty](https://alacritty.org/)~~ [kitty](https://sw.kovidgoyal.net/kitty/)
- Editor: [neovim](https://neovim.io/)
- Multiplexer: ~~[tmux](https://github.com/tmux/tmux/wiki)~~ [zellij](https://zellij.dev/)
- Prompt: [starship](https://starship.rs/)
- Browser: ~~[arc](https://arc.net/)~~ Back to safari...
- Docker: [orbstack](https://orbstack.dev/)
- Network: [tailscale](https://tailscale.com/)
- Window Tiling Manager: [aerospace](https://nikitabobko.github.io/AeroSpace/guide)

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

#### Old

```bash
sudo nix --extra-experimental-features 'nix-command flakes' build .#darwinConfigurations.your-local-hostname.system
```

#### New

```bash
// run this at the root of this directory
nix run nix-darwin -- switch --flake ~/nix-system-config-v2/.#Kyles-MacBook-Air
```

### Initialise darwin rebuild

```bash
darwin-rebuild switch --flake ~/nix-system-config-v2
```

### Cleanup

```bash
bash ~/nix-system-config/cleanup.sh
```

### Installing NPM packages that are not available in Nix

Navigate to `...../modules/home-manager/node-packages` and run the following command to generate a nix expression. The expression can then be added into home manager

- `-18` is to build with nodejs v18

```bash
nix-shell -p nodePackages.node2nix --command "node2nix -18 -i ./node-packages.json -o node"
```
