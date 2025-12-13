{ pkgs, ... }:
{
  home.packages = with pkgs; [
    custom.cmd
  ];
}
