{ pkgs, ... }:
{
  home.packages = with pkgs; [
    custom.cpenv
  ];
}
