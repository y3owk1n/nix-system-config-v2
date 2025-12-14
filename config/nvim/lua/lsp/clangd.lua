---@type LspModule
local M = {}

M.enabled = vim.fn.executable("clangd") == 1

function M.setup()
  vim.lsp.enable("clangd")
end

return M
