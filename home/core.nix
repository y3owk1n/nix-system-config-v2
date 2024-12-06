{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # utils
    fd
    curl
    jq
    tree
    less
    ripgrep
    # gnused
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
    alacritty

    # --- rust ---
    cargo

    # --- node ---
    corepack_latest
    fnm
    bun

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
