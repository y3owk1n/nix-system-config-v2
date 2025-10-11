{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ast-grep
  ];
}
