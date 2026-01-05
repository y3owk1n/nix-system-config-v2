---@type PluginModule
local M = {}

M.name = "nvim-treesitter"

M.lazy = {
  event = "VeryLazy",
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
}

M.post_pack_changed = function()
  vim.cmd("TSUpdate")
end

M.registry = {
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "main",
    name = "nvim-treesitter",
  },
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
    "json5",
    "just",
    "luadoc",
    "luap",
    "nix",
    "prisma",
    "javascript",
    "jsdoc",
    "tsx",
    "typescript",
    "yaml",
    -- these are already included by neovim default
    -- "query",
    -- "vim",
    -- "vimdoc",
    -- "lua",
    -- "markdown",
    -- "markdown_inline",
  }

  -- no need to call setup(), see `https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md#setup`

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
    group = vim.api.nvim_create_augroup("nvim-treesitter-ft", { clear = true }),
    callback = function()
      pcall(vim.treesitter.start)

      vim.bo.syntax = "ON"

      -- folds, provided by Neovim
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      -- indentation, provided by nvim-treesitter
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return M
