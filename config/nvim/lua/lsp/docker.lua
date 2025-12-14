---@type LspModule
local M = {}

M.enabled = vim.fn.executable("docker-language-server") == 1 or vim.fn.executable("docker-compose-langserver") == 1

function M.setup()
  if vim.fn.executable("docker-language-server") == 1 then
    vim.lsp.enable("docker_language_server")
  end

  if vim.fn.executable("docker-compose-langserver") == 1 then
    vim.lsp.enable("docker_compose_language_service")
  end
end

return M
