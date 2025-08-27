---@type PluginModule
local M = {}

M.name = "cloak"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = "https://github.com/laytan/cloak.nvim", name = "cloak" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "cloak")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
