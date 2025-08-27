---@type PluginModule
local M = {}

M.name = "supermaven-nvim"

M.lazy = {
  event = "InsertEnter",
}

M.registry = {
  { src = "https://github.com/supermaven-inc/supermaven-nvim", name = "supermaven-nvim" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "supermaven-nvim")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    keymaps = {
      accept_suggestion = "<C-y>",
    },
    ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
  }

  plugin.setup(plugin_opts)
end

return M
