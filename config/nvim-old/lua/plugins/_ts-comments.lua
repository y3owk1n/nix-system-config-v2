---@type PluginModule
local M = {}

M.name = "ts-comments"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = "https://github.com/folke/ts-comments.nvim", name = "ts-comments" },
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
