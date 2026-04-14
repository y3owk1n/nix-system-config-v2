{ inputs, ... }:
{
  flake.homeConfigurations = {
    "fedora" = import ../hosts/fedora.nix { inherit inputs; };
  };
}
