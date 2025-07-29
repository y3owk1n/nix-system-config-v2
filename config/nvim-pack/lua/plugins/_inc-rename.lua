---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "inc_rename")

  if not plugin_ok then
    return
  end

  plugin.setup({})

  --- setting keymaps
  vim.keymap.set("n", "grn", function()
    return ":IncRename " .. vim.fn.expand("<cword>")
  end, { desc = "Rename word", expr = true })
end

return M
