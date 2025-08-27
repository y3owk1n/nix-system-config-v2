---@type PluginModule
local M = {}

M.name = "custom.lazygit"

M.enabled = false

M.lazy = {
  keys = {
    "<leader>gg",
  },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "custom-plugins.lazygit")

  if not plugin_ok then
    return
  end

  ---@type Lazygit.Config
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>gg", function()
    plugin.open()
  end, { desc = "Open Lazygit" })
end

return M
