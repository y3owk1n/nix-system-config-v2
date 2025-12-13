{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cmd
  ];
}
