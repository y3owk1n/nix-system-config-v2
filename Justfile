# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Darwin related commands
#
############################################################################

init ARG:
    bash ./scripts/init.sh {{ARG}}

rebuild:
    darwin-rebuild switch --verbose --impure --flake .

extra-node:
    bash ./scripts/install-node-packages.sh

############################################################################
#
#  nix related commands
#
############################################################################


update:
    sudo nix flake update

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

start-kanata:
    sudo kanata -n -c ~/.config/kanata/config.kbd

