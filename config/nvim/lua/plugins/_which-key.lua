---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "which-key")

  if not plugin_ok then
    return
  end

  vim.o.timeout = true
  vim.o.timeoutlen = 500

  ---@class wk.Opts
  local plugin_opts = {
    preset = "helix",
    icons = {
      mappings = true,
      -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
      -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
      keys = {},
    },

    spec = {
      {
        mode = { "n", "v" },
        { "<leader>c", group = "code" },
        { "<leader>cg", group = "generate" },
        { "<leader>g", group = "git" },
        { "<leader>f", group = "files" },
        { "<leader>q", group = "quit/session" },
        { "<leader>s", group = "search" },
        { "<leader>i", group = "info" },
        { "<leader>l", group = "lsp" },
        {
          "<leader>u",
          group = "ui",
          icon = { icon = "󰙵 ", color = "cyan" },
        },
        {
          "<leader>x",
          group = "diagnostics/quickfix",
          icon = { icon = "󱖫 ", color = "green" },
        },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "gs", group = "surround" },
        { "gr", group = "lsp" },
        {
          "<leader>w",
          group = "windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        -- better descriptions
        { "gx", desc = "Open with system app" },
      },
    },
  }

  plugin.setup(plugin_opts)
end

return M
