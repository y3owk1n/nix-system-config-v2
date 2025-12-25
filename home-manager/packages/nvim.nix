{
  pkgs,
  config,
  ...
}:
{
  # ============================================================================
  # Neovim Dependencies
  # ============================================================================

  home.packages =
    with pkgs;
    [
      # ============================================================================
      # Language Servers & Development Tools
      # ============================================================================

      # so that neovim works properly
      lua51Packages.lua
      luajitPackages.luarocks

      # so that we can build treesitter in neovim
      tree-sitter

      shfmt
      shellcheck
      bash-language-server
      vscode-langservers-extracted # includes html, css, json, eslint, json lsp is part of it and noramlly a config file
      marksman # markdown is not project specific
      markdownlint-cli2 # markdown is not project specific
      yaml-language-server # yaml normally used as a config language
      prettierd # general formatter
      gh-actions-language-server # from custom flake

      # These are project specific lsp or tools
      # They should be installed in the project via devbox or direnv flake

      # lua-language-server
      # stylua

      # biome
      # vtsls
      # tailwindcss-language-server
      # prisma-language-server # from `nixos-npm-ls` flake

      # clang-tools

      # nixd

      # just-lsp

      # gopls
      # gotools # includes godoc, goimports, callgraph, digraph, stringer or toolstash
      # gofumpt
      # golangci-lint

      # docker-compose-language-service
      # docker-language-server
      # hadolint

      # ============================================================================
      # Neovim Configuration
      # ============================================================================
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.neovim
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
