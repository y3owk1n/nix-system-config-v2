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
