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

### SSH keys import

Get ip from fedora with `ip a`

#### From host

```bash
# move all the .gpg and public keys to the fedora
scp <file> kylewong@<ip>:/home/kylewong/ssh_trans # ensure `ssh_trans` is created at fedora
```

#### on fedora

```bash
cd /home/kylewong/ssh_trans
gpg --decrypt <filename>.gpg > ~/.ssh/<filename>
chmod 600 ~/.ssh/<filename>
cp <filename>.pub ~/.ssh/<filename>.pub

ssh-add ~/.ssh/<filename> # add to ssh-agent
ssh-add -l # to check
```

### GPG keys import

#### From host

```bash
# move all the `._sec.asr.gpg` and `_pub.asc` to the fedora
scp <file> kylewong@<ip>:/home/kylewong/gpg_trans # ensure `gpg_trans` is created at fedora
```

#### on fedora

```bash
cd /home/kylewong/gpg_trans
gpg --decrypt <filename>_sec.asc.gpg > <filename>_sec.asc
gpg --import <filename>_sec.asc
shred -u <filename>_sec.asc
gpg --import <filename>_pub.asc

gpg --list-secret-keys --keyid-format LONG # to check all the gpg keys
gpg --edit-key <gpg-key-id> # to edit the key, and then run `trust` and `5` and `quit`
```

- ensure gh is setup by running `gh auth login`
