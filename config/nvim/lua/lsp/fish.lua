---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable({
    "dockerls",
    "docker_compose_language_service",
  })
end

return M
