{ pkgs, ... }:
{
  home.packages = with pkgs; [
    custom.move-to-space
  ];
}
