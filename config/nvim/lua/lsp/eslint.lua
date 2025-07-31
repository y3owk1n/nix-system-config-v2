---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("eslint")
end

return M
