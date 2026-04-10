local lspconfig_util = require("lspconfig.util")

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
