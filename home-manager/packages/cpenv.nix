{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cpenv
  ];
}
