---@type PluginModule
local M = {}

M.name = "inc_rename"

M.lazy = {
  cmd = "IncRename",
  keys = { "grn" },
}

M.registry = {
  { src = "https://github.com/smjonas/inc-rename.nvim", name = "inc_rename" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "inc_rename")

  if not plugin_ok then
    return
  end

  ---@type inc_rename.UserConfig
  local plugin_opts = {}

  plugin.setup(plugin_opts)

  --- setting keymaps
  vim.keymap.set("n", "grn", function()
    return ":IncRename " .. vim.fn.expand("<cword>")
  end, { desc = "Rename word", expr = true })
end

return M
