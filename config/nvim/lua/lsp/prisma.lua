---@type LspModule
local M = {}

M.enabled = vim.fn.executable("prisma-language-server") == 1

function M.setup()
  vim.lsp.enable("prismals")
end

return M
