---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("prismals")
end

return M
