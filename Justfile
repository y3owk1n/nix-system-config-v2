# ============================================================================
# Justfile - Command Runner for Nix System Management
# ============================================================================
# This file contains commands for managing the Nix Darwin system configuration.
# Use `just <command>` to run any of these recipes.
# ============================================================================
# Darwin System Commands
# ============================================================================

[macos]
init host:
    bash ./scripts/init.sh {{ host }}

# Rebuild and switch to the specified host configuration

# If no host is specified, rebuilds the current system
[macos]
rebuild host="":
    sudo -i darwin-rebuild switch --impure --flake ~/nix-system-config-v2/.{{ if host != "" { "#" + host } else { "" } }}

[linux]
rebuild host="":
    sudo nixos-rebuild switch --impure --flake .{{ if host != "" { "#" + host } else { "" } }}

############################################################################
#
#  nix related commands
#
############################################################################

[macos]
update:
    sudo -i determinate-nixd upgrade
    nix flake update

[linux]
update:
    nix flake update

history:
    nix profile history --profile /nix/var/nix/profiles/system

gc:
    # remove all generations older than 7 days
    sudo -i nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

    # garbage collect all unused nix store entries
    sudo -i nix store gc --debug

    sudo -i nix-collect-garbage -d

    sudo -i nix store optimise

fmt:
    # format the files in this repo
    nix fmt

check:
    # run flake checks
    nix flake check

dev:
    # enter development environment
    nix develop

clean:
    rm -rf result

############################################################################
#
#  Misc commands
#
############################################################################

nvim-reset:
    bash ./scripts/nvim-reset.sh

[macos]
start-kanata:
    tmux new-window -n "kanata" "just kanata"

[macos]
kanata:
    sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon' &
    sudo kanata -n -c ~/.config/kanata/config.kbd

mirror-nvim:
    git subtree split --prefix=config/nvim -b nvim-config
    git remote add nvim-config https://github.com/y3owk1n/nvim.git
    git push nvim-config nvim-config:main

user := `uname -n`
icloud_drive_path := "/Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs"
ssh_backup_path := icloud_drive_path + "/ssh/" + user

# Backup SSH keys to iCloud Drive (encrypted with GPG)
[macos]
backup-ssh:
    mkdir -p {{ ssh_backup_path }}
    for key in ~/.ssh/id_*; do \
      case "$key" in *.pub) continue ;; esac; \
      if [ -f "$key" ]; then \
        name=`basename $key`; \
        echo "Encrypting $name..."; \
        gpg --symmetric --cipher-algo AES256 \
          --output {{ ssh_backup_path }}/$name.gpg $key; \
        if [ -f "$key.pub" ]; then \
          cp "$key.pub" {{ ssh_backup_path }}/$name.pub; \
        fi; \
      fi; \
    done

# Restore SSH keys from iCloud Drive backup
[macos]
restore-ssh:
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    for keyfile in {{ ssh_backup_path }}/*.gpg; do
      base=$(basename "$keyfile")
      name="${base%.gpg}"
      echo "Restoring $name..."
      gpg --decrypt "$keyfile" > ~/.ssh/"$name"
      chmod 600 ~/.ssh/"$name"
      if [ -f {{ ssh_backup_path }}/"$name.pub" ]; then
        cp {{ ssh_backup_path }}/"$name.pub" ~/.ssh/"$name.pub"
      fi
    done

ssh_backup_path_orb := "/mnt/mac" + icloud_drive_path + "/ssh/"

[linux]
restore-ssh-orb user:
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    for keyfile in {{ ssh_backup_path_orb }}/{{ user }}/*.gpg; do
      base=$(basename "$keyfile")
      name="${base%.gpg}"
      echo "Restoring $name..."
      gpg --decrypt "$keyfile" > ~/.ssh/"$name"
      chmod 600 ~/.ssh/"$name"
      if [ -f {{ ssh_backup_path_orb }}/{{ user }}/"$name.pub" ]; then
        cp {{ ssh_backup_path_orb }}/{{ user }}/"$name.pub" ~/.ssh/"$name.pub"
      fi
    done

ssh_backup_path_vmware := "/mnt/hfgs/ssh"

[linux]
restore-ssh-vmware user:
    #!/usr/bin/env bash
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    for keyfile in {{ ssh_backup_path_vmware }}/{{ user }}/*.gpg; do
      base=$(basename "$keyfile")
      name="${base%.gpg}"
      echo "Restoring $name..."
      gpg --decrypt "$keyfile" > ~/.ssh/"$name"
      chmod 600 ~/.ssh/"$name"
      if [ -f {{ ssh_backup_path_vmware }}/{{ user }}/"$name.pub" ]; then
        cp {{ ssh_backup_path_vmware }}/{{ user }}/"$name.pub" ~/.ssh/"$name.pub"
      fi
    done

gpg_backup_path := icloud_drive_path + "/gpg/" + user

# Backup GPG key pair to iCloud Drive (encrypted)
[macos]
backup-gpg gpg_key:
    mkdir -p {{ gpg_backup_path }}
    # Export secret key in ASCII armor format
    gpg --armor --export-secret-keys "{{ gpg_key }}" > {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    # Encrypt the secret key file
    gpg --symmetric --cipher-algo AES256 \
        --output {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc.gpg \
        {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    # Securely delete the unencrypted secret key
    shred -u {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    # Export public key
    gpg --armor --export "{{ gpg_key }}" > {{ gpg_backup_path }}/{{ gpg_key }}_pub.asc

# Restore GPG key pair from iCloud Drive backup
[macos]
restore-gpg gpg_key:
    # Decrypt the private key
    gpg --decrypt {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc.gpg > {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    # Import back to GPG
    gpg --import {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    # Remove the decrypted file
    shred -u {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    # Import public key (optional)
    gpg --import {{ gpg_backup_path }}/{{ gpg_key }}_pub.asc

gpg_backup_path_from_vm := "/mnt/mac/" + icloud_drive_path + "/gpg/"

[linux]
restore-gpg user gpg_key:
    # Decrypt the private key
    gpg --decrypt {{ gpg_backup_path_from_vm }}/{{ user }}/{{ gpg_key }}_sec.asc.gpg > {{ gpg_backup_path_from_vm }}/{{ user }}/{{ gpg_key }}_sec.asc
    # Import back to GPG
    gpg --import {{ gpg_backup_path_from_vm }}/{{ user }}/{{ gpg_key }}_sec.asc
    # Remove the decrypted file
    shred -u {{ gpg_backup_path_from_vm }}/{{ user }}/{{ gpg_key }}_sec.asc
    # Import public key (optional)
    gpg --import {{ gpg_backup_path_from_vm }}/{{ user }}/{{ gpg_key }}_pub.asc

gpg_backup_path_vmware := "/mnt/hgfs/gpg/"

[linux]
restore-gpg-vmware user gpg_key:
    # Decrypt the private key
    gpg --decrypt {{ gpg_backup_path_vmware }}/{{ user }}/{{ gpg_key }}_sec.asc.gpg > {{ gpg_backup_path_vmware }}/{{ user }}/{{ gpg_key }}_sec.asc
    # Import back to GPG
    gpg --import {{ gpg_backup_path_vmware }}/{{ user }}/{{ gpg_key }}_sec.asc
    # Remove the decrypted file
    shred -u {{ gpg_backup_path_vmware }}/{{ user }}/{{ gpg_key }}_sec.asc
    # Import public key (optional)
    gpg --import {{ gpg_backup_path_vmware }}/{{ user }}/{{ gpg_key }}_pub.asc
