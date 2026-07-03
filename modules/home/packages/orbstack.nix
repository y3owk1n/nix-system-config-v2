{ pkgs, ... }:
{
  home.packages = with pkgs; [
    orbstack
  ];
}
