---@type PluginModule
local M = {}

M.name = "flash"

M.lazy = {
  keys = {
    "s",
  },
}

M.registry = {
  "https://github.com/folke/flash.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "flash")

  if not plugin_ok then
    return
  end

  ---@type Flash.Config
  local plugin_opts = {
    prompt = {
      enabled = false,
    },
  }

  plugin.setup(plugin_opts)

  vim.keymap.set({ "n", "x", "o" }, "s", function()
    vim.g.ug_ignore_cursor_moved = true
    plugin.jump()

    vim.defer_fn(function()
      local undo_glow_ok, undo_glow = pcall(require, "undo-glow")

      if not undo_glow_ok then
        return
      end

      local region = require("undo-glow.utils").get_current_cursor_row()

      local undo_glow_opts = require("undo-glow.utils").merge_command_opts("UgSearch", {
        force_edge = true,
      })

      undo_glow.highlight_region(vim.tbl_extend("force", undo_glow_opts, region))
    end, 5)
  end, { desc = "Flash" })
end

return M
