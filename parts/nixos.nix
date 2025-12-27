{
  inputs,
  ...
}:

{
  flake.nixosConfigurations = {
    "nixos-orb" = import ./hosts/nixos-orb.nix { inherit inputs; };
    "nixos-vmware-fusion" = import ./hosts/nixos-vmware-fusion.nix { inherit inputs; };
    "nixos-vb" = import ./hosts/nixos-vb.nix { inherit inputs; };
  };
}
