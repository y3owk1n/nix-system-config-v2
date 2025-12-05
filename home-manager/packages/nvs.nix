{ pkgs, ... }:
{
  programs.nvs = {
    enable = true;
    package = pkgs.nvs-source;
  };
}
