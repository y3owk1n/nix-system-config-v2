---@type LspModule
local M = {}

M.enabled = vim.fn.executable("nixd") == 1

function M.setup()
  vim.lsp.enable("nixd")
end

return M
