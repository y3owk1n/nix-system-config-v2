{ config, ... }:
{
  home.file."aerospace" = {
    enable = true;
    recursive = false;
    source = "${config.home.homeDirectory}/nix-system-config-v2/config/aerospace";
    target = "/.config/aerospace";
  };
}
