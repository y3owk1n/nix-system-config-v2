return {
  "dmmulroy/ts-error-translator.nvim",
  init = function()
    local allowed_clients = { "vtsls" }

    require("k92.utils.lazy").lazy_load_lsp_attach(allowed_clients, "ts-error-translator.nvim")
  end,
  opts = {},
}
