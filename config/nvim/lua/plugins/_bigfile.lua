---@type PluginModule
local M = {}

M.name = "custom.bigfile"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.bigfile")

  if not plugin_ok then
    return
  end

  ---@type BigFile.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
