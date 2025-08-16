---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "VeryLazy" },
  lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
  cmd = { "TSUpdate", "TSInstall" },
  config = function()
    local plugin = require("nvim-treesitter")

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
  end,
}
