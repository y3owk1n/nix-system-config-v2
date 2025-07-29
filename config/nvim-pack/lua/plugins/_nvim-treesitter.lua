---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "nvim-treesitter.configs")

  if not plugin_ok then
    return
  end

  local ensure_installed = {
    "html",
    "regex",
    "toml",
    "query",
    "vim",
    "vimdoc",
    "xml",
    "css",
    "kdl",
    "bash",
    "dockerfile",
    "fish",
    "git_config",
    "gitcommit",
    "git_rebase",
    "gitignore",
    "gitattributes",
  }

  -- setup
  plugin.setup({
    highlight = { enable = true },
    indent = { enable = true },
    ensure_installed = ensure_installed,
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  })

  -- add file types
  vim.filetype.add({
    pattern = {
      ["docker?-compose?.ya?ml"] = "yaml.docker-compose",
    },
  })
end

return M
