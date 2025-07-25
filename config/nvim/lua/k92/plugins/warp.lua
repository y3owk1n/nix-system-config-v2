---@type LazySpec
return {
  {
    "y3owk1n/warp.nvim",
    -- dir = "~/Dev/warp.nvim", -- Your path
    cmd = {
      "WarpAddFile",
      "WarpShowList",
      "WarpClearCurrentList",
      "WarpClearAllList",
      "WarpGoToIndex",
    },
    ---@module "warp"
    ---@type Warp.Config
    opts = {},
    keys = {
      {
        "<leader>h",
        "",
        desc = "warp",
      },
      {
        "<leader>ha",
        "<cmd>WarpAddFile<cr>",
        desc = "[Warp] Add",
      },
      {
        "<leader>hh",
        "<cmd>WarpShowList<cr>",
        desc = "[Warp] Show list",
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
