-- =========================================================
--  Lua overrides (so that vim don't shout at me)
-- =========================================================

vim.lsp.config("lua_ls", {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath("config")
        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
      then
        return
      end
    end

    local library = {
      vim.env.VIMRUNTIME,
      vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
      vim.api.nvim_get_runtime_file("lua/base16-pro-max", false)[1],
      vim.api.nvim_get_runtime_file("lua/conform", false)[1],
      vim.api.nvim_get_runtime_file("lua/notifier", false)[1],
      vim.api.nvim_get_runtime_file("lua/nvim-tmux-navigation", false)[1],
      vim.api.nvim_get_runtime_file("lua/nvim-treesitter", false)[1],
      vim.api.nvim_get_runtime_file("lua/supermaven-nvim", false)[1],
      vim.api.nvim_get_runtime_file("lua/undo-glow", false)[1],
    }

    -- get all mini files in the runtimepath
    -- the reason is that all standalon mini are in the same `lua/mini` folder...
    vim.list_extend(library, vim.api.nvim_get_runtime_file("lua/mini", true))

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using (most
        -- likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
        -- Tell the language server how to find Lua modules same way as Neovim
        -- (see `:h lua-module-load`)
        path = {
          "lua/?.lua",
          "lua/?/init.lua",
        },
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = library,
        -- Or pull in all of 'runtimepath'.
        -- NOTE: this is a lot slower and will cause issues when working on
        -- your own configuration.
        -- See https://github.com/neovim/nvim-lspconfig/issues/3189
        -- library = vim.api.nvim_get_runtime_file('', true),
      },
    })
  end,
  settings = {
    Lua = {
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

-- list of mappings that the executable name is different from the lspserver name
local lsp_exec_map = {
  bashls = "bash-language-server",
  docker_language_server = "docker-language-server",
  eslint = "vscode-eslint-language-server",
  fish_lsp = "fish-lsp",
  gh_actions_ls = "gh-actions-language-server",
  golangci_lint_ls = "golangci-lint-langserver",
  jsonls = "vscode-json-language-server",
  just = "just-lsp",
  lua_ls = "lua-language-server",
  prismals = "prisma-language-server",
  tailwindcss = "tailwindcss-language-server",
  yamlls = "yaml-language-server",
}

---Enable LSP if executable is available from a list
---@param lsps string[]
local function enable_lsp_if_available(lsps)
  for _, lsp in ipairs(lsps) do
    local executable = lsp_exec_map[lsp] or lsp
    if executable and vim.fn.executable(executable) == 1 then
      vim.lsp.enable(lsp)
    end
  end
end

enable_lsp_if_available({
  "bashls",
  "biome",
  "clangd",
  "docker_language_server",
  "eslint",
  "fish_lsp",
  "gh_actions_ls",
  "gopls",
  "golangci_lint_ls",
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
