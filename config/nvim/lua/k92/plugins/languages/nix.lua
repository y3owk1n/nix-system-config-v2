local _table = require("k92.utils.table")

if not vim.g.has_nix then
  return {}
end

vim.lsp.enable("nil_ls")

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "nix" } },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if vim.fn.executable("nil") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "nil" })
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
      },
    },
  },
}
