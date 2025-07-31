---@type LspModule
local M = {}

function M.setup()
  vim.lsp.config("just", {
    on_attach = function(client)
      client.server_capabilities.documentFormattingProvider = false
    end,
  })

  vim.lsp.enable("just")
end

return M
