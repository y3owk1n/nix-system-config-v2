---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "todo-comments")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    signs = false,
  }

  plugin.setup(plugin_opts)

  vim.keymap.set("n", "]t", function()
    plugin.jump_next()
  end, { desc = "Next Todo Comment" })

  vim.keymap.set("n", "[t", function()
    plugin.jump_prev()
  end, { desc = "Previous Todo Comment" })
end

return M
