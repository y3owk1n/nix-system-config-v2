---@type PluginModule
local M = {}

M.name = "mini-files-git"

M.after = {
  "mini.files",
}

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/mini-files-git", name = "mini-files-git" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini-files-git")

  if not plugin_ok then
    return
  end

  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
