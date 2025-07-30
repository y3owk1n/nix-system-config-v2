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

function M.setup()
  vim.pack.add({ "https://github.com/windwp/nvim-ts-autotag" })

  local plugin_ok, plugin = pcall(require, "nvim-ts-autotag")

  if not plugin_ok then
    return
  end

  ---@type nvim-ts-autotag.PluginSetup
  local plugin_opts = {}

  plugin.setup(plugin_opts)
end

return M
