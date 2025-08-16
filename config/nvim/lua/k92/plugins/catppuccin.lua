---@type LazySpec
return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  opts = function()
    local colors = require("catppuccin.palettes").get_palette()
    local c_utils = require("catppuccin.utils.colors")

    ---@type CatppuccinOptions
    local opts = {
      float = {
        solid = false,
        transparent = true,
      },
      default_integrations = false,
      integrations = {
        blink_cmp = {
          enabled = true,
          style = "bordered",
        },
        flash = true,
        grug_far = true,
        markdown = true,
        mini = {
          enabled = true,
          indentscope_color = "flamingo",
        },
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
        treesitter = true,
        render_markdown = true,
        snacks = {
          enabled = true,
        },
        which_key = true,
      },
      custom_highlights = {
        --- general
        ["@property"] = { fg = colors.lavender }, -- For fields, like accessing `bar` property on `foo.bar`. Overriden later for data languages and CSS.
        --- for `blink_cmp`
        --- override to match `float.transparent` settings
        BlinkCmpMenu = { link = "FloatBorder", bg = colors.none },
        BlinkCmpMenuBorder = { link = "FloatBorder", bg = colors.none },
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

    return opts
  end,
  config = function(_, opts)
    local plugin = require("catppuccin")
    plugin.setup(opts)

    vim.cmd.colorscheme("catppuccin-macchiato")
  end,
}
