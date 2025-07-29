---@type PluginModule
local M = {}

M.lazy = {
  on_lsp_attach = { "vtsls" },
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
