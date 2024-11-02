{ pkgs, config, ... }:
let
  extraNodePackages = import ./node-packages/default.nix { inherit pkgs; };
in
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
    rustup

    # --- node ---
    corepack_latest
    fnm
    bun

    # --- extraNodePackages ---
    extraNodePackages.cpenv

    # --- nvim ---
    lua51Packages.lua
    luajitPackages.luarocks

    # --- nix ---
    nixfmt-rfc-style
  ];
}
