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

[linux]
rebuild-hm host="":
    home-manager switch --impure --flake .{{ if host != "" { "#" + host } else { "" } }}

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
