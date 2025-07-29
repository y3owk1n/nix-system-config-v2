---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "render-markdown")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    heading = {
      sign = false,
      icons = {},
    },
    checkbox = {
      enabled = false,
    },
  }

  plugin.setup(plugin_opts)
end

return M
