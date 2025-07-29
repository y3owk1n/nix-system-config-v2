---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.diff")

  if not plugin_ok then
    return
  end

  plugin.setup({
    view = {
      style = "sign",
      signs = {
        add = "▎",
        change = "▎",
        delete = "",
      },
    },
  })

  vim.keymap.set("n", "<leader>gd", function()
    plugin.toggle_overlay(0)
  end, { desc = "Toggle diff overlay" })
end

return M
