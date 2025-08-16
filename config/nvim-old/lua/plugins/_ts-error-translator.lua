---@type PluginModule
local M = {}

M.name = "ts-error-translator"

M.lazy = {
  on_lsp_attach = { "vtsls" },
}

M.registry = {
  "https://github.com/dmmulroy/ts-error-translator.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "ts-error-translator")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
