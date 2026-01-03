---@type LspModule
local M = {}

M.enabled = vim.fn.executable("cargo") == 1

function M.setup()
  vim.lsp.enable("rust_analyzer")
end

return M
