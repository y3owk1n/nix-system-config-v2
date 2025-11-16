{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    lua51Packages.lua
    luajitPackages.luarocks
    panvimdoc
    # --- neovim language servers ---
    tree-sitter
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
    nixd
    prisma-language-server # from `nixos-npm-ls` flake
    tailwindcss-language-server
    vtsls
    yaml-language-server
    biome
    prettierd
    clang-tools
  ];

  xdg.configFile.nvim = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim";
    # recursive = true;
  };

  xdg.configFile.nvim-old = {
    enable = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-system-config-v2/config/nvim-old";
    # recursive = true;
  };
}
