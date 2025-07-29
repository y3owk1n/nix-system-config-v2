local _table = require("k92.utils.table")

if not vim.g.has_node then
  return {}
end

vim.lsp.enable("prismals")

---@type LazySpec
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "prisma" },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      if vim.fn.executable("prisma-language-server") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "prisma-language-server" })
      end
    end,
  },
}
