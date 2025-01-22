{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # utils
    fd
    jq
    tree
    less
    ripgrep
    ast-grep
    mkcert
    rip2

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

    # --- nix ---
    nixfmt-rfc-style
  ];
}
