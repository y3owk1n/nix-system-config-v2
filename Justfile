# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Darwin related commands
#
############################################################################

[macos]
init host:
    bash ./scripts/init.sh {{ host }}

[macos]
rebuild host="":
    sudo darwin-rebuild switch --impure --flake .{{ if host != "" { "#" + host } else { "" } }}

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
    sudo determinate-nixd upgrade
    nix flake update

[linux]
update:
    nix flake update

history:
    nix profile history --profile /nix/var/nix/profiles/system

gc:
    # remove all generations older than 7 days
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

    # garbage collect all unused nix store entries
    sudo nix store gc --debug

    sudo nix-collect-garbage -d

    sudo nix store optimise

fmt:
    # format the nix files in this repo
    nix fmt

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

gpg_backup_path := icloud_drive_path + "/gpg/" + user

[macos]
backup-gpg gpg_key:
    mkdir -p {{ gpg_backup_path }}
    gpg --armor --export-secret-keys "{{ gpg_key }}" > {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    gpg --symmetric --cipher-algo AES256 \
        --output {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc.gpg \
        {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    shred -u {{ gpg_backup_path }}/{{ gpg_key }}_sec.asc
    gpg --armor --export "{{ gpg_key }}" > {{ gpg_backup_path }}/{{ gpg_key }}_pub.asc

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

[macos]
relaunch-skhd:
    launchctl bootout gui/$(id -u)/org.nix-community.home.skhd
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.skhd.plist

[macos]
relaunch-atauin-daemon:
    pkill -9 atuin
    rip ~/.local/share/atuin/daemon.sock
    launchctl bootout gui/$(id -u)/org.nix-community.home.atuin-daemon
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.atuin-daemon.plist

[macos]
relaunch-gpg-agent:
    gpgconf --kill gpg-agent
    gpgconf --launch gpg-agent
