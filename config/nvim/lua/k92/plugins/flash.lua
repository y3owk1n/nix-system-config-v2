---@type LazySpec
return {
  "folke/flash.nvim",
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        local plugin = require("flash")

        local ug_ok, ug = pcall(require, "undo-glow")

        if ug_ok then
          vim.g.ug_ignore_cursor_moved = true
        end

        plugin.jump()

        if ug_ok then
          vim.defer_fn(function()
            local region = require("undo-glow.utils").get_current_cursor_row()

            local undo_glow_opts = require("undo-glow.utils").merge_command_opts("UgSearch", {
              force_edge = true,
            })

            ug.highlight_region(vim.tbl_extend("force", undo_glow_opts, region))
          end, 5)
        end
      end,
      desc = "Flash",
    },
  },
  ---@type Flash.Config
  ---@diagnostic disable-next-line: missing-fields
  opts = {
    prompt = {
      enabled = false,
    },
  },
}
