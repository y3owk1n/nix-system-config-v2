---@type PluginModule
local M = {}

M.name = "bigfile"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/bigfile", name = "bigfile" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "bigfile")

  if not plugin_ok then
    return
  end

  ---@type BigFile.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
