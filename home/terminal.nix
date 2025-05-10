{ config, ... }:
{
  xdg.configFile.ghostty = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/ghostty";
    recursive = true;
  };
}
