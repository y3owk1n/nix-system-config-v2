---@type LspModule
local M = {}

M.enabled = vim.fn.executable("gopls") == 1

function M.setup()
  vim.lsp.enable("gopls")
end

return M
