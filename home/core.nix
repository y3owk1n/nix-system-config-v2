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

    # --- rust ---
    cargo

    # --- node ---
    # corepack_latest
    corepack_22 # pin to 22 instead, latest is fetching rc versions
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
