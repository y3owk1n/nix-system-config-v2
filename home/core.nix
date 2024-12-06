{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    # utils
    fd
    curl
    jq
    tree
    less
    ripgrep

    # --- misc ---
    stripe-cli
    minio
    just

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
