{ config, ... }:
{
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
    };
  };

  home.file."nvim" = {
    enable = true;
    recursive = false;
    source = "${config.home.homeDirectory}/nix-system-config-v2/config/nvim";
    target = "/.config/nvim";
  };
}
