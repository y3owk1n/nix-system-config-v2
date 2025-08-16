---@type LazySpec
return {
  {
    "folke/flash.nvim",
    ---@type Flash.Config
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      prompt = {
        enabled = false,
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          vim.g.ug_ignore_cursor_moved = true
          require("flash").jump()

          vim.defer_fn(function()
            local region = require("undo-glow.utils").get_current_cursor_row()

            local undo_glow_opts = require("undo-glow.utils").merge_command_opts("UgSearch", {
              force_edge = true,
            })

            require("undo-glow").highlight_region(vim.tbl_extend("force", undo_glow_opts, region))
          end, 5)
        end,
        desc = "Flash",
      },
    },
  },
}
