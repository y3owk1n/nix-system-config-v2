---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "render-markdown")

  if not plugin_ok then
    return
  end

  plugin.setup({
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
  })
end

return M
