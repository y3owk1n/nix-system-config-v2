{ config, ... }:
{
  home.file."kanata" = {
    enable = true;
    recursive = false;
    source = "${config.home.homeDirectory}/nix-system-config-v2/config/kanata";
    target = "/.config/kanata";
  };
}
