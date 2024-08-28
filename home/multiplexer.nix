{ config, ... }:
{
  home.file."zellij" = {
    enable = true;
    recursive = false;
    source = "${config.home.homeDirectory}/nix-system-config-v2/config/zellij";
    target = "/.config/zellij";
  };
}
