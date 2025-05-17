{
  pkgs,
  nixos-prismals,
  nixos-gh-action-ls,
  ...
}:
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
    stylua
    bash-language-server
    biome
    docker-compose-language-service
    docker-language-server
    hadolint
    shfmt
    shellcheck
    vscode-langservers-extracted # includes html, css, json, eslint
    gopls
    gotools # includes godoc, goimports, callgraph, digraph, stringer or toolstash
    gofumpt
    golangci-lint
    just-lsp
    marksman
    markdownlint-cli2
    nil
    tailwindcss-language-server
    vtsls
    eslint
    yaml-language-server
    nodePackages.prettier
    nixos-prismals.packages.${pkgs.system}.default
    nixos-gh-action-ls.packages.${pkgs.system}.default
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
    IS_ORBSTACK = 1;
  };

  # Additional setup for fish alias
  programs.fish.shellAliases = {
    "tailscale" = "mac tailscale";
    "minio" = "mac minio";
    "stripe" = "mac stripe";
    "gh" = "mac gh";
  };
}
