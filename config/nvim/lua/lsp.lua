-- =========================================================
--  Just overrides
-- =========================================================

vim.lsp.config("just", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
})

-- =========================================================
--  Lua overrides (so that vim don't shout at me)
-- =========================================================

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      completion = { enable = true },
      diagnostics = {
        enable = true,
        globals = { "vim" },
      },
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

-- =========================================================
--  Nixd overrides (so that i can get some completion for nix)
-- =========================================================

local flake_path = vim.fn.expand("~/nix-system-config-v2")
local hostname = vim.fn.trim(vim.fn.hostname())

vim.lsp.config("nixd", {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", ".git" },
  settings = {
    nixd = {
      nixpkgs = {
        expr = string.format([[import (builtins.getFlake "%s").inputs.nixpkgs { }]], flake_path),
      },
      options = {
        darwin = {
          expr = string.format([[(builtins.getFlake "%s").darwinConfigurations."%s".options]], flake_path, hostname),
        },
        -- enable this if on nixos machine
        -- nixos = {
        --   expr = string.format([[(builtins.getFlake "%s").nixosConfigurations."%s".options]], flake_path, hostname),
        -- },
        -- enable this if on home-manager machine
        -- ["home-manager"] = {
        --   expr = string.format([[(builtins.getFlake "%s").homeConfigurations."%s".options]], flake_path, hostname),
        -- },
        ["flake-parts"] = {
          expr = string.format([[(builtins.getFlake "%s").debug.options]], flake_path),
        },
      },
    },
  },
})

-- =========================================================
--  Tailwind overrides
-- =========================================================

--- see https://github.com/neovim/nvim-lspconfig/pull/4376
--- put the following in the root of project `.nvim.lua`
--- and then `:trust` it

-- vim.lsp.config("tailwindcss", {
--   settings = {
--     tailwindCSS = {
--       experimental = {
--         configFile = "packages/ui/src/styles.css", -- change this to the path to the global css for tailwind
--       },
--     },
--   },
--   root_dir = function(bufnr, on_dir)
--     local root_files = {
--       ".git",
--     }
--     local fname = vim.api.nvim_buf_get_name(bufnr)
--     on_dir(vim.fs.dirname(vim.fs.find(root_files, { path = fname, upward = true })[1]))
--   end,
-- })

-- =========================================================
--  Enable LSPs
-- =========================================================

vim.lsp.enable({
  "bashls",
  "biome",
  "clangd",
  "docker_language_server",
  "docker_compose_language_service",
  "eslint",
  "gh_actions_ls",
  "gopls",
  "jsonls",
  "just",
  "lua_ls",
  "marksman",
  "nixd",
  "prismals",
  "rust_analyzer",
  "tailwindcss",
  "vtsls",
  "yamlls",
})
