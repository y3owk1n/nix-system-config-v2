# My Personal Nix System Configuration

This is a project to help me to manage my Nix system configuration, mainly with Darwin and Home Manager.

## What do I use?

### General

- Shell: [fish](https://fishshell.com/)
- Terminal: [ghostty](https://ghostty.org/)
- Editor: [neovim](https://neovim.io/)
- Multiplexer: [tmux](https://github.com/tmux/tmux/wiki)
- Prompt: [starship](https://starship.rs/)
- Browser: [zen browser](https://zen-browser.app/)
- Docker: [orbstack](https://orbstack.dev/)
- Network: [tailscale](https://tailscale.com/)
- Launcher: [raycast](https://www.raycast.com/)
- Window Tiling Manager: [aerospace](https://nikitabobko.github.io/AeroSpace/guide)

## Safari Extensions

- [Web Shield (Beta)](https://github.com/arjpar/WebShield) - like ublock origin
- [VimLike](https://www.jasminestudios.net/vimlike/) - like vimium
- [Refined Github](https://github.com/refined-github/refined-github) - better github experience

## Notes for future me

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

### Quad9 DNS

#### Macos Issue

To check the dns settings, run the following command

```bash
scutil --dns
```

Then verify it from [dnscheck](https://www.dnscheck.tools/)

if for some reason it is not using the dns provided by Quad9, set the dns addresses of quad9 to the wifi/ethernet settings

Then flush the dns cache

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

And then run the test again and it should work now on both

- dnscheck
- quad9 test page

### Fish

> [!note]
> No longer required, since `catppuccin-nix` flake handles everything for themeing.

Set theme for fish

```bash
fish_config theme save "Catppuccin Macchiato"
```

### Git SSH Key

[More Info from github docs](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/checking-for-existing-ssh-keys)
[Reference for home manager](https://jeppesen.io/git-commit-sign-nix-home-manager-ssh/)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "email@example.com"

# Add the following to ~/.ssh/config
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519

# Add to SSH Agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Add to Github
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "personal laptop"
```

### Orbstack related

Using macos host docker in nixos

[Reference](https://github.com/orbstack/orbstack/issues/269#issuecomment-1548858675)

```bash
mac link docker
```

### GPG related

When doing backup, always use the secret key as input

```bash
gpg --list-secret-keys --keyid-format LONG

# and grab the one after rsa4096
```

### PASS related

> [!note]
> For now I am only using pass as a secret manager with my `passx` scripts that supports project scoping with different
> environments.

When doing multiple machines with single store, ensure the following

- Machine A & B needs to have their own private key
- Machine A needs to have the public key of Machine B
- Machine B needs to have the public key of Machine A

Then we can init the pass

```bash
pass init <pubkey-machine-a> <pubkey-machine-b>
```

> [!note]
> When rotating keys, make sure to have the new pubkeys in both machines, do not delete the old private key first
>
> - do the init again with the new keys
> - then ensure we can access the passwords
> - then delete the old private key and public key
