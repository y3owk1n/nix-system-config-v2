---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("clangd")
end

return M
