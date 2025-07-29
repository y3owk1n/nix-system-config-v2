---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, package = pcall(require, "catppuccin")

  if not plugin_ok then
    return
  end

  local colors = require("catppuccin.palettes").get_palette()

  package.setup({
    default_integrations = false,
    integrations = {
      treesitter = true,
      mini = {
        enabled = true,
        indentscope_color = "flamingo",
      },
      blink_cmp = {
        style = "bordered",
      },
      grug_far = true,
      flash = true,
      snacks = {
        enabled = true,
      }
    },
    custom_highlights = {
      BlinkCmpLabel = { fg = colors.overlay2 },
      BlinkCmpMenu = { fg = colors.text },
      BlinkCmpMenuBorder = { fg = colors.blue },
      BlinkCmpDoc = { fg = colors.overlay2 },
      BlinkCmpDocBorder = { fg = colors.blue },
      BlinkCmpSignatureHelpBorder = { fg = colors.blue },
    }
  })

  vim.cmd.colorscheme("catppuccin-macchiato")
end

return M
