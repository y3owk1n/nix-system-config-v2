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
      padding = { left = 1, right = 1 },
      is_global = false,
      unset = {
        ft = {
          "time-machine-list",
          "cmd",
          "help",
          "nofile",
        },
        bt = { "nofile" },
      },
      show_default = {
        bt = { "nofile", "terminal" },
      },
      layout = {
        left = { "git", "diff", "warp" },
        center = {},
        right = { "lsp", "position", "progress" },
      },
    },

    winbar = {
      enabled = true,
      padding = { left = 1, right = 1 },
      unset = {
        ft = {
          "time-machine-list",
          "help",
        },
        bt = { "nofile" },
      },
      show_default = {
        bt = { "nofile", "terminal" },
      },
      layout = {
        left = { "fileinfo" },
        right = { "diagnostics" },
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
