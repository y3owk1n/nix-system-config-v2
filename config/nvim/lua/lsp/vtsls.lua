---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("vtsls")
end

return M
