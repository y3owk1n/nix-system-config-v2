---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("lua_ls")
end

return M
