vim.lsp.config("just", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
})

vim.lsp.enable("just")
