---@type PluginModule
local M = {}

M.name = "nvim-ts-autotag"

M.lazy = {
  ft = {
    "javascriptreact",
    "javascript.jsx",
    "typescriptreact",
    "typescript.tsx",
    "html",
  },
}

M.registry = {
  { src = "https://github.com/windwp/nvim-ts-autotag", name = "nvim-ts-autotag" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "nvim-ts-autotag")

  if not plugin_ok then
    return
  end

  ---@type nvim-ts-autotag.PluginSetup
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
