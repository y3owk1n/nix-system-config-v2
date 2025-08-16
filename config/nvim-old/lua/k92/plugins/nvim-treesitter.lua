---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "VeryLazy" },
    lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treesitter** module to be loaded in time.
      -- Luckily, the only things that those plugins need are the custom queries, which we make available
      -- during startup.
      require("lazy.core.loader").add_to_rtp(plugin)
    end,
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
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
    end,
  },
}
