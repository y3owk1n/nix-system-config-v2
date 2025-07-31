---@type PluginModule
local M = {}

M.name = "nvim-treesitter"

M.lazy = {
  event = "UIEnter",
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
}

function M.setup()
  vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

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
    "go",
    "gomod",
    "gowork",
    "gosum",
    "json",
    "jsonc",
    "json5",
    "just",
    "lua",
    "luadoc",
    "luap",
    "markdown",
    "markdown_inline",
    "nix",
    "prisma",
    "javascript",
    "jsdoc",
    "tsx",
    "typescript",
    "yaml",
  }

  ---@type TSConfig
  ---@diagnostic disable-next-line: missing-fields
  local plugin_opts = {
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
  }

  -- setup
  plugin.setup(plugin_opts)

  -- add file types
  vim.filetype.add({
    pattern = {
      ["docker?-compose?.ya?ml"] = "yaml.docker-compose",
    },
  })
  vim.filetype.add({
    extension = { just = "just" },
    filename = {
      justfile = "just",
      Justfile = "just",
      [".Justfile"] = "just",
      [".justfile"] = "just",
    },
  })
  vim.filetype.add({
    extension = { mdx = "markdown.mdx" },
  })
  vim.treesitter.language.register("markdown", "markdown.mdx")
end

return M
