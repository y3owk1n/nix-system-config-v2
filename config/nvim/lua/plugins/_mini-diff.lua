---@type PluginModule
local M = {}

M.name = "mini.diff"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

function M.setup()
  vim.pack.add({ "https://github.com/echasnovski/mini.diff" })

  local plugin_ok, plugin = pcall(require, "mini.diff")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    view = {
      style = "sign",
      signs = {
        add = "▎",
        change = "▎",
        delete = "",
      },
    },
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "<leader>gd", function()
    plugin.toggle_overlay(0)
  end, { desc = "Toggle diff overlay" })
end

return M
