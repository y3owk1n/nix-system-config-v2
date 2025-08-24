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
      layout = {
        left = { "mode", "git", "diff", "warp" },
        center = { "fileinfo", "diagnostics" },
        right = { "macro", "search", "lsp", "position", "progress" },
      },
    },

    mode = {
      prefix = "[",
      suffix = "]",
    },

    git = {
      condition = function()
        return vim.bo.filetype ~= ""
      end,
    },

    diff = {
      condition = function()
        return vim.bo.filetype ~= ""
      end,
    },

    lsp = {
      detail_prefix = "[",
      detail_suffix = "]",
    },

    diagnostics = {
      show_info = true,
      show_hint = true,
      condition = function()
        return vim.bo.filetype ~= ""
      end,
    },

    warp = {
      enabled = true,
    },

    macro = {
      enabled = true,
    },

    search = {
      enabled = true,
    },

    progress = {
      use_bar = true,
    },
  },
}
