---@type PluginModule
local M = {}

M.name = "nvim-lspconfig"

M.lazy = {
  event = { "UIEnter" },
}

function M.setup()
  vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

  local plugin_ok, _ = pcall(require, "lspconfig")

  if not plugin_ok then
    return
  end

  vim.schedule(function()
    require("lsp")
  end)
end

return M
