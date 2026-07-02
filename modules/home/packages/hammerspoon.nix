{ config, ... }:
{
  home.file.".hammerspoon" = {
    enable = false;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/hammerspoon";
    # recursive = true;
  };
}
