---@type LspModule
local M = {}

M.enabled = vim.fn.executable("vtsls") == 1

function M.setup()
  vim.lsp.enable("vtsls")
end

return M
