---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("yamlls")
end

return M
