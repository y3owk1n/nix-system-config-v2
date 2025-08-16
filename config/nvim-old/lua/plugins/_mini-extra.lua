---@type PluginModule
local M = {}

M.name = "mini.extra"

M.lazy = {
  event = { "UIEnter" },
}

M.registry = {
  "https://github.com/echasnovski/mini.extra",
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
