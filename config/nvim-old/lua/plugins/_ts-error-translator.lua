---@type PluginModule
local M = {}

M.name = "ts-error-translator"

M.lazy = {
  on_lsp_attach = { "vtsls" },
}

M.registry = {
  { src = "https://github.com/dmmulroy/ts-error-translator.nvim", name = "ts-error-translator" },
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
