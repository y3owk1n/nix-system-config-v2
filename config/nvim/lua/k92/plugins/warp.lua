---@type LazySpec
return {
  {
    "y3owk1n/warp.nvim",
    -- dir = "~/Dev/warp.nvim", -- Your path
    event = "VeryLazy",
    cmd = {
      "WarpAddFile",
      "WarpShowList",
      "WarpClearCurrentList",
      "WarpClearAllList",
      "WarpGoToIndex",
    },
    ---@module "warp"
    ---@type Warp.Config
    opts = {
      keymaps = {
        move_up = { "K" },
        move_down = { "J" },
      },
    },
    keys = {
      {
        "<leader>ha",
        function()
          require("warp.action").add()
        end,
        desc = "[Warp] Add",
      },
      {
        "<leader>hh",
        function()
          require("warp.action").show_list()
        end,
        desc = "[Warp] Show list",
      },
      {
        "<leader>hx",
        function()
          require("warp.list").clear_current_list()
        end,
        desc = "[Warp] Clear current list",
      },
      {
        "<leader>hX",
        function()
          require("warp.list").clear_all_list()
        end,
        desc = "[Warp] Clear all lists",
      },
      {
        "<leader>1",
        function()
          require("warp.action").goto_index(1)
        end,
        desc = "[Warp] Goto #1",
      },
      {
        "<leader>2",
        function()
          require("warp.action").goto_index(2)
        end,
        desc = "[Warp] Goto #2",
      },
      {
        "<leader>3",
        function()
          require("warp.action").goto_index(3)
        end,
        desc = "[Warp] Goto #3",
      },
      {
        "<leader>4",
        function()
          require("warp.action").goto_index(4)
        end,
        desc = "[Warp] Goto #4",
      },
    },
  },
}
