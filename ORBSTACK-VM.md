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

- ssh keys are setup by default via orbstack, but it's good to restore the one that i want to
- `just restore-ssh-orb <user>`
- ensure ssh keys are added by running `ssh-add ~/.ssh/id_ed25519`
- run `ssh-add -l` to check

- ensure gpg keys are imported
- run `just restore-gpg <user> <gpg-key-id>`
- run `gpg --list-secret-keys --keyid-format LONG` to check
- run `gpg --edit-key <gpg-key-id>` to edit the key, and then run `trust` and `5` and `quit`

- ensure gh is setup by running `gh auth login`
