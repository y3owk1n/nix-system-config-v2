local _table = require("k92.utils.table")

vim.lsp.enable("marksman")

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      _table.add_unique_items(opts.ensure_installed, { "markdown", "markdown_inline" })
      vim.filetype.add({
        extension = { mdx = "markdown.mdx" },
      })
      vim.treesitter.language.register("markdown", "markdown.mdx")
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end,
        },
      },
      formatters_by_ft = {
        ["markdown"] = { "prettierd", "markdownlint-cli2" },
        ["markdown.mdx"] = { "prettierd", "markdownlint-cli2" },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if vim.fn.executable("marksman") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "marksman" })
      end

      if vim.g.has_node and vim.fn.executable("markdownlint-cli2") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "markdownlint-cli2" })
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint-cli2" },
        ["markdown.mdx"] = { "markdownlint-cli2" },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = {},
      },
      checkbox = {
        enabled = false,
      },
    },
    ft = { "markdown", "markdown.mdx", "norg", "rmd", "org" },
  },
  {
    "catppuccin/nvim",
    optional = true,
    opts = {
      integrations = {
        markdown = true,
        render_markdown = true,
      },
    },
  },
}
