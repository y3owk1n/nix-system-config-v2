---@type PluginModule
local M = {}

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "ts-comments")

  if not plugin_ok then
    return
  end

  ---@type TSCommentsOptions
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
