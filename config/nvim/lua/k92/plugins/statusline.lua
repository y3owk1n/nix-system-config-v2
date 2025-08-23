local custom_name = "statusline"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  event = "VeryLazy",
  name = custom_name,
  init = function()
    vim.opt.laststatus = 0 -- disable the statusline and let the plugin to handle it
  end,
  ---@type Statusline.Config
  opts = {
    padding = { left = 1, right = 1 },
    layout = {
      left = { "mode", "git", "diff", "warp", "time" },
      center = { "fileinfo" },
      right = { "diagnostics", "lsp", "position", "progress" },
    },

    lsp = {
      detail_prefix = "[",
      detail_suffix = "]",
    },

    fileinfo = {
      max_length = 80,
      path_style = "relative",
    },

    diagnostics = {
      show_info = true,
      show_hint = true,
    },

    warp = {
      enabled = true,
    },
    post_setup_fn = function()
      vim.opt.laststatus = 3 -- Global statusline
    end,
  },
  config = function(_, opts)
    local sm = require("statusline")

    sm.setup(opts)
  end,
}
