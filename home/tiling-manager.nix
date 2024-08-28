{ config, ... }:
{
  xdg.configFile.aerospace = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/aerospace";
    recursive = true;
  };
}
