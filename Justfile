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
