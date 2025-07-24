local _table = require("k92.utils.table")

if not vim.g.has_bash then
  return {}
end

if vim.g.has_node then
  vim.lsp.enable("bashls")
end

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "bash" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if vim.fn.executable("shfmt") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "shfmt" })
      end

      if vim.fn.executable("shellcheck") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "shellcheck" })
      end

      if vim.g.has_node and vim.fn.executable("bash-language-server") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "bash-language-server" })
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
      },
    },
  },
}
