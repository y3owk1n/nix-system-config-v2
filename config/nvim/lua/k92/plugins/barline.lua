local custom_name = "barline"

---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/k92/custom-plugins/" .. custom_name,
  event = "VeryLazy",
  name = custom_name,
  init = function()
    vim.opt.laststatus = 0 -- disable the statusline and let the plugin to handle it
  end,
  ---@type Barline.Config
  opts = {
    statusline = {
      enabled = true,
      is_global = true,
      show_default = {
        bt = { "nofile", "terminal", "help" },
      },
      layout = {
        left = { "git", "diff", "warp" },
        center = { "fileinfo", "diagnostics" },
        right = { "lsp", "position", "progress" },
      },
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
  },
}
