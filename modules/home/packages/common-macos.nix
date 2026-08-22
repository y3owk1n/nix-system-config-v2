{ pkgs, ... }:
{
  home.packages = with pkgs; [
    custom.affinity
    custom.mole
    orbstack
    stripe-cli
  ];
}
