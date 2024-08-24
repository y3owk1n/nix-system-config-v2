{ pkgs, config, ... }:
let
  extraNodePackages = import ./node-packages/default.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    ripgrep
    rustup
    corepack_latest
    fnm
    bun
    fd
    minio
    rm-improved
    fd
    curl
    less
    minio
    jq
    tree
    stripe-cli
    postgresql
    lua51Packages.lua
    luajitPackages.luarocks # for nvim
    nixfmt-rfc-style # for nvim
    # --- extraNodePackages ---
    extraNodePackages.cpenv
  ];

  programs = {
    # modern vim
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
    };

    # A modern replacement for ‘ls’
    # useful in bash/zsh prompt, not in nushell.
    eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = true;
    };

    # skim provides a single executable: sk.
    # Basically anywhere you would want to use grep, try sk instead.
    skim = {
      enable = true;
      enableBashIntegration = true;
    };
  };

  xdg.configFile = {
    nvim = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim";
      recursive = true;
    };
    zellij = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/zellij";
      recursive = true;
    };
    # wezterm = {
    #   source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/wezterm";
    #   recursive = true;
    # };
    # alacritty = {
    #   source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/alacritty";
    #   recursive = true;
    # };
    aerospace = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/aerospace";
      recursive = true;
    };
    # kitty = {
    #   source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/kitty";
    #   recursive = true;
    # };
  };

}
