- Create a new VM via obstack with nixos
- ssh into the VM
- `sudo nano /etc/nixos/configuration.nix`
- Add the following to the nixos configuration

```nix
environment.systemPackages = with pkgs; [ git vim ];
```

- `sudo nixos-rebuild switch`
- go to `~` and clone the repo `git clone https://github.com/y3owk1n/nix-system-config-v2.git`
- run `sudo nixos-rebuild switch --impure --flake .`

- paste the age identity into `~/.config/sops/age/keys.txt` and rebuild, sops-nix installs the SSH key
- run `ssh-add -l` to check

- ensure gh is setup by running `gh auth login`
