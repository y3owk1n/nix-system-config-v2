{
  inputs,
  ...
}:

{
  flake.darwinConfigurations = {
    "Kyles-MacBook-Air" = import ./hosts/personal-m3.nix { inherit inputs; };
    "Kyles-iMac" = import ./hosts/work-imac.nix { inherit inputs; };
  };
}
