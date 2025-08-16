---@type LspModule
local M = {}

function M.setup()
  vim.lsp.enable({
    "docker_language_server",
    "docker_compose_language_service",
  })
end

return M
