---@type LspModule
local M = {}

M.enabled = vim.fn.executable("lua-language-server") == 1

function M.setup()
  vim.lsp.enable("lua_ls")
end

return M
