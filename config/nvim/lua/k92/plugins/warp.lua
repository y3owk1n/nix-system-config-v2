---@type LazySpec
return {
  {
    "y3owk1n/warp.nvim",
    -- dir = "~/Dev/warp.nvim", -- Your path
    cmd = {
      "WarpAddFile",
      "WarpAddOnScreenFiles",
      "WarpDelFile",
      "WarpMoveTo",
      "WarpShowList",
      "WarpClearCurrentList",
      "WarpClearAllList",
      "WarpGoToIndex",
    },
    ---@module "warp"
    ---@type Warp.Config
    opts = {
      keymaps = {
        split_horizontal = { "-" },
        split_vertical = { "\\" },
      },
      window = {
        list = function(lines)
          -- get all the line widths
          local line_widths = vim.tbl_map(vim.fn.strdisplaywidth, lines)
          -- set the width te either the max width or at least 30 characters
          local max_width = math.max(math.max(unpack(line_widths)), 30)
          -- set the height to if the number of lines is less than 8 then 8
          -- otherwise the number of lines
          local max_height = #lines < 8 and 8 or math.min(#lines, vim.o.lines - 3)
          -- get the current height of the TUI
          local nvim_tui_height = vim.api.nvim_list_uis()[1]

          return {
            width = max_width,
            height = max_height,
            row = nvim_tui_height.height - max_height - 4,
            col = 0,
          }
        end,
      },
    },
    keys = {
      {
        "<leader>h",
        "",
        desc = "warp",
      },
      {
        "<leader>hm",
        "",
        desc = "move",
      },
      {
        "<leader>ha",
        "<cmd>WarpAddFile<cr>",
        desc = "[Warp] Add",
      },
      {
        "<leader>hA",
        "<cmd>WarpAddOnScreenFiles<cr>",
        desc = "[Warp] Add all on screen files",
      },
      {
        "<leader>hd",
        "<cmd>WarpDelFile<cr>",
        desc = "[Warp] Delete",
      },
      {
        "<leader>he",
        "<cmd>WarpShowList<cr>",
        desc = "[Warp] Show list",
      },
      {
        "<leader>hml",
        "<cmd>WarpMoveTo next<cr>",
        desc = "[Warp] Move to next index",
      },
      {
        "<leader>hmh",
        "<cmd>WarpMoveTo prev<cr>",
        desc = "[Warp] Move to prev index",
      },
      {
        "<leader>hmL",
        "<cmd>WarpMoveTo last<cr>",
        desc = "[Warp] Move to the last index",
      },
      {
        "<leader>hmH",
        "<cmd>WarpMoveTo first<cr>",
        desc = "[Warp] Move to first index",
      },
      {
        "<leader>hx",
        "<cmd>WarpClearCurrentList<cr>",
        desc = "[Warp] Clear current list",
      },
      {
        "<leader>hX",
        "<cmd>WarpClearAllList<cr>",
        desc = "[Warp] Clear all lists",
      },
      {
        "<leader>hl",
        "<cmd>WarpGoToIndex next<cr>",
        desc = "[Warp] Goto next index",
      },
      {
        "<leader>hh",
        "<cmd>WarpGoToIndex prev<cr>",
        desc = "[Warp] Goto prev index",
      },
      {
        "<leader>hH",
        "<cmd>WarpGoToIndex first<cr>",
        desc = "[Warp] Goto first index",
      },
      {
        "<leader>hL",
        "<cmd>WarpGoToIndex last<cr>",
        desc = "[Warp] Goto last index",
      },
      {
        "<leader>1",
        "<cmd>WarpGoToIndex 1<cr>",
        desc = "[Warp] Goto #1",
      },
      {
        "<leader>2",
        "<cmd>WarpGoToIndex 2<cr>",
        desc = "[Warp] Goto #2",
      },
      {
        "<leader>3",
        "<cmd>WarpGoToIndex 3<cr>",
        desc = "[Warp] Goto #3",
      },
      {
        "<leader>4",
        "<cmd>WarpGoToIndex 4<cr>",
        desc = "[Warp] Goto #4",
      },
    },
  },
}
