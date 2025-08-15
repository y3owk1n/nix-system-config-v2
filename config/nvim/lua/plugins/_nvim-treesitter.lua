---@type PluginModule
local M = {}

M.name = "nvim-treesitter"

M.lazy = {
  event = "UIEnter",
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
}

M.registry = {
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "nvim-treesitter")

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

  -- setup
  plugin.setup()

  plugin.install(ensure_installed)

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

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ensure_installed,
    callback = function()
      -- syntax highlighting, provided by Neovim
      vim.treesitter.start()
      -- folds, provided by Neovim
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      -- indentation, provided by nvim-treesitter
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return M
