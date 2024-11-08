{ config, ... }:
{
  xdg.configFile.alacritty = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/alacritty";
    recursive = true;
  };
}
