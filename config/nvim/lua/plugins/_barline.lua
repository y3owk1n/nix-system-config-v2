---@type PluginModule
local M = {}

M.name = "barline"

M.lazy = {
  event = {
    "VeryLazy",
  },
}

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/barline", name = "barline" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "barline")

  if not plugin_ok then
    return
  end

  vim.opt.laststatus = 0 -- disable the statusline and let the plugin to handle it

  ---@type Barline.Config
  local plugin_opts = {
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
  }

  plugin.setup(plugin_opts)
end

return M
