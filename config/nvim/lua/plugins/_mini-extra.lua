---@type PluginModule
local M = {}

M.name = "mini.extra"

M.lazy = {
  event = { "UIEnter" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.extra")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
