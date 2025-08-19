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

icloud_drive_path := "/Users/kylewong/Library/Mobile\\ Documents/com~apple~CloudDocs"
gpg_key := ""
gpg_file_prefix := gpg_key
gpg_backup_path := icloud_drive_path + "/gpg/" + gpg_key + "/"

[macos]
backup-gpg:
    mkdir -p {{ gpg_backup_path }}
    # Export your secret key (ASCII armored)
    # gpg --fingerprint
    gpg --armor --export-secret-keys {{ gpg_key }} > {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc
    # Encrypt the exported key with a passphrase
    gpg --symmetric --cipher-algo AES256 --output {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc.gpg {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc
    # Remove the unencrypted file
    shred -u {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc
    # Optionally, also backup the public key
    gpg --armor --export {{ gpg_key }} > {{ gpg_backup_path }}/{{ gpg_file_prefix }}_pub.asc

[macos]
restore-gpg:
    # Decrypt the private key
    gpg --decrypt {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc.gpg > {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc
    # Import back to GPG
    gpg --import {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc
    # Remove the decrypted file
    shred -u {{ gpg_backup_path }}/{{ gpg_file_prefix }}_sec.asc
    # Import public key (optional)
    gpg --import {{ gpg_backup_path }}/{{ gpg_file_prefix }}_pub.asc

[macos]
relaunch-skhd:
    launchctl bootout gui/$(id -u)/org.nixos.skhd
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nixos.skhd.plist
