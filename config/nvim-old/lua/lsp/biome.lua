---@type LspModule
local M = {}

M.enabled = vim.fn.executable("biome") == 1

function M.setup()
  vim.lsp.enable("biome")
end

return M
