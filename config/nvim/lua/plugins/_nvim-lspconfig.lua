---@type PluginModule
local M = {}

M.name = "nvim-lspconfig"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

  local plugin_ok, _ = pcall(require, "lspconfig")

  if not plugin_ok then
    return
  end

  vim.schedule(function()
    require("lsp").init()
  end)
end

return M
