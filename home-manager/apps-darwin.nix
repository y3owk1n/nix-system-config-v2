{ config, pkgs, ... }:
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
    just

    # --- rust ---
    # cargo

    # --- node ---
    nodejs_22
    # corepack_latest
    # corepack_22 # pin to 22 instead, latest is fetching rc versions

    # --- nix ---
    nixfmt-rfc-style

    # --- neovim language servers ---
    shfmt
    shellcheck
    bash-language-server
    docker-compose-language-service
    docker-language-server
    hadolint
    gh-actions-language-server # from `nixos-npm-ls` flake
    gopls
    gotools # includes godoc, goimports, callgraph, digraph, stringer or toolstash
    gofumpt
    golangci-lint
    vscode-langservers-extracted # includes html, css, json, eslint
    just-lsp
    lua-language-server
    stylua
    marksman
    markdownlint-cli2
    nil
    prisma-language-server # from `nixos-npm-ls` flake
    tailwindcss-language-server
    vtsls
    yaml-language-server
    biome
    prettierd
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
      arguments = [
        "--hidden"
        "--glob=!.git/*"
        "--smart-case"
      ];
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
  home.sessionVariables = {
    RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.config/ripgrep/ripgreprc";
  };
}
