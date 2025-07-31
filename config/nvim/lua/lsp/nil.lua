---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("nil_ls")
end

return M
