---@type PluginModule
local M = {}

M.enabled = false

M.name = "mini.notify"

M.registry = {
  "https://github.com/echasnovski/mini.notify",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.notify")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
