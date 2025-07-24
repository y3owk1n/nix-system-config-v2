---@type vim.lsp.Config
return {
  cmd = { "just-lsp" },
  filetypes = { "just" },
  root_markers = { ".git" },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
}
