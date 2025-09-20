{ config, ... }:
{
  xdg.configFile.keyboardcowboy = {
    enable = false;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/keyboardcowboy";
    # recursive = true;
  };
}
