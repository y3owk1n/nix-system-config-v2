---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("marksman")
end

return M
