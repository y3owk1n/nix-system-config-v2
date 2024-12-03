{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    # --- utils ---
    ripgrep
    fd
    curl
    jq
    tree

    # --- misc ---
    less
    stripe-cli
    postgresql
    minio

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
