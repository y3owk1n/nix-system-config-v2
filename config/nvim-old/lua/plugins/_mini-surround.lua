---@type PluginModule
local M = {}

M.name = "mini.surround"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = "https://github.com/nvim-mini/mini.surround", name = "mini.surround" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.surround")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    mappings = {
      add = "gsa", -- Add surrounding in Normal and Visual modes
      delete = "gsd", -- Delete surrounding
      find = "gsf", -- Find surrounding (to the right)
      find_left = "gsF", -- Find surrounding (to the left)
      highlight = "gsh", -- Highlight surrounding
      replace = "gsr", -- Replace surrounding
    },
  }

  plugin.setup(plugin_opts)
end

return M
