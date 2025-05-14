{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # --- utils ---
    tree
    mkcert
    rip2
    imagemagick
    ghostscript
    ninja
    cmake
    gettext
    ast-grep

    # --- misc ---
    stripe-cli
    minio
    just

    # --- rust ---
    cargo

    # --- node ---
    nodejs_23
    # corepack_latest
    corepack_22 # pin to 22 instead, latest is fetching rc versions

    # --- nix ---
    nixfmt-rfc-style
  ];

  # Apps that only requires single `enable = true`
  programs = {
    fd = {
      enable = true;
    };
    jq = {
      enable = true;
    };
    ripgrep = {
      enable = true;
    };
    less = {
      enable = true;
    };
    zoxide = {
      enable = true;
    };
    btop = {
      enable = true;
    };
  };
}
