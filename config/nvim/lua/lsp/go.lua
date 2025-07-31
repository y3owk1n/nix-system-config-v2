---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("gopls")
end

return M
