{ config, ... }:
{
  xdg.configFile.zellij = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/zellij";
    recursive = true;
  };
}
