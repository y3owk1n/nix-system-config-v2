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
    nodejs_22
    # corepack_latest
    corepack_22 # pin to 22 instead, latest is fetching rc versions

    # --- nix ---
    nixfmt-rfc-style

    # --- neovim language servers ---
    lua-language-server
    bash-language-server
    biome
    docker-compose-language-service
    docker-language-server
    vscode-langservers-extracted
    gopls
    just-lsp
    marksman
    nil
    tailwindcss-language-server
    vtsls
    yaml-language-server
    nodePackages.prettier
    markdownlint-cli2
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

  # Additional setup for neovim formatter bins
  home.sessionVariables = {
    BIOME_BINARY = "${pkgs.biome}/bin/biome";
  };
}
