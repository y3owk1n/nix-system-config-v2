{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
  ];
}
