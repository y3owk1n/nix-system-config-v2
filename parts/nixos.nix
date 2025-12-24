{
  inputs,
  ...
}:

{
  flake.nixosConfigurations = {
    "nixos-orb" = import ./hosts/nixos-orb.nix { inherit inputs; };
  };
}
