{ pkgs, ... }:
{
  home.packages = with pkgs; [
    mkcert
  ];
}
