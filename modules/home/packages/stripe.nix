{ pkgs, ... }:
{
  home.packages = with pkgs; [
    stripe-cli
  ];
}
