{ config, ... }:
{
  home.file.".paneru.toml" = {
    enable = false;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/paneru/paneru.toml";
    # recursive = true;
  };
}
