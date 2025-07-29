local _table = require("k92.utils.table")

if not vim.g.has_node then
  return {}
end

vim.lsp.enable("gh_actions_ls")

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if vim.fn.executable("gh-actions-language-server") == 0 then
        _table.add_unique_items(opts.ensure_installed, { "gh-actions-language-server" })
      end
    end,
  },
}
