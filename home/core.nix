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
    chafa

    # --- apps ---
    keka
    appcleaner
    brave

    # --- terminal ---
    # alacritty

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
