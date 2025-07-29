---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "catppuccin")

  if not plugin_ok then
    return
  end

  local colors = require("catppuccin.palettes").get_palette()

  local c_utils = require("catppuccin.utils.colors")

  ---@type CatppuccinOptions
  local plugin_opts = {
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
      },
      markdown = true,
      render_markdown = true,
      which_key = true,
      native_lsp = {
        enabled = true,
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
          ok = { "italic" },
        },
        underlines = {
          errors = { "underline" },
          hints = { "underline" },
          warnings = { "underline" },
          information = { "underline" },
          ok = { "underline" },
        },
        inlay_hints = {
          background = true,
        },
      },
    },
    custom_highlights = {
      --- for blink.cmp
      BlinkCmpLabel = { fg = colors.overlay2 },
      BlinkCmpMenu = { fg = colors.text },
      BlinkCmpMenuBorder = { fg = colors.blue },
      BlinkCmpDoc = { fg = colors.overlay2 },
      BlinkCmpDocBorder = { fg = colors.blue },
      BlinkCmpSignatureHelpBorder = { fg = colors.blue },
      --- for time-machine.nvim
      TimeMachineCurrent = {
        bg = c_utils.darken(colors.blue, 0.18, colors.base),
      },
      TimeMachineTimeline = { fg = colors.blue, style = { "bold" } },
      TimeMachineTimelineAlt = { fg = colors.overlay2 },
      TimeMachineKeymap = { fg = colors.teal, style = { "italic" } },
      TimeMachineInfo = { fg = colors.subtext0, style = { "italic" } },
      TimeMachineSeq = { fg = colors.peach, style = { "bold" } },
      TimeMachineTag = { fg = colors.yellow, style = { "bold" } },
    },
  }

  plugin.setup(plugin_opts)

  vim.cmd.colorscheme("catppuccin-macchiato")
end

return M
