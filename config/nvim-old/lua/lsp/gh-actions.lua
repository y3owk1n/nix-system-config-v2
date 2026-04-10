---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable("gh_actions_ls")
end

return M
