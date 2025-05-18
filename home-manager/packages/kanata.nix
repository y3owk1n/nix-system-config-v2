{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    kanata
  ];

  xdg.configFile.kanata = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/kanata";
    recursive = true;
  };
}
