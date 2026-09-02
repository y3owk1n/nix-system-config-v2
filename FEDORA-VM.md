- Create a new VM via UTM with fedora latest
- log into the VM

- Install nix

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

- go to `~` and clone the repo `git clone https://github.com/y3owk1n/nix-system-config-v2.git`

- Install home manager

```bash
nix run github:nix-community/home-manager -- switch --impure --flake .#fedora
```

- To rebuild use `just rebuild-hm fedora`

### Change shell to fish

```bash
which fish # check the path

cat /etc/shells # check the list of shells, if it doesn't have fish, add it

which fish | sudo tee -a /etc/shells # only add fish to the list if we dont have it

chsh -s $(which fish) # change the shell
```

### Secrets

Paste the age identity into `~/.config/sops/age/keys.txt`, then rebuild.
sops-nix installs the SSH key. See DOCS.md, Secrets.

- ensure gh is setup by running `gh auth login`
