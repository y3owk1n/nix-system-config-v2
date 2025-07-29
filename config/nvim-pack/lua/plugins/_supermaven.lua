---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "supermaven-nvim")

  if not plugin_ok then
    return
  end

  plugin.setup({
    keymaps = {
      accept_suggestion = "<C-y>",
    },
    ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
  })
end

return M
