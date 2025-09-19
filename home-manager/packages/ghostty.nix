{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty-bin # this is the darwin version, `ghostty` is for linux only
  ];
  xdg.configFile.ghostty = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/ghostty";
    # recursive = true;
  };
}
