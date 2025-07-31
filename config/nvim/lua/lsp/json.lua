---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("jsonls")
end

return M
