---@type PluginModule
local M = {}

M.name = "mini.extra"

M.lazy = {
  event = { "VeryLazy" },
}

M.registry = {
  { src = "https://github.com/echasnovski/mini.extra", name = "mini.extra" },
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
