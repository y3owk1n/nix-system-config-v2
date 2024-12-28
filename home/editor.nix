{
  config,
  pkgs,
  neovim-nightly-overlay,
  ...
}:
{
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      # package = neovim-nightly-overlay.packages.${pkgs.system}.default;
    };
  };

  xdg.configFile.nvim-lazyvim = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim-lazyvim";
    recursive = true;
  };

  xdg.configFile.nvim = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim";
    recursive = true;
  };
}
