{ pkgs, ... }:
{
  programs.uts = {
    enable = true;
    package = pkgs.uts-source;
  };
}
