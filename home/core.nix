{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # utils
    fd
    jq
    tree
    less
    ripgrep
    mkcert
    rip2
    imagemagick
    ghostscript

    # --- misc ---
    # sqlite
    stripe-cli
    minio
    just
    btop

    # --- apps ---
    keka
    appcleaner
    brave

    # --- terminal ---
    # alacritty # used for quick editing only (specifically neovim embed for text inputs)

    # --- rust ---
    cargo

    # --- node ---
    corepack_latest
    fnm

    # --- go ---
    go
    cobra-cli

    # --- nvim ---
    lua51Packages.lua
    luajitPackages.luarocks
    panvimdoc

    # --- nix ---
    nixfmt-rfc-style
  ];
}
