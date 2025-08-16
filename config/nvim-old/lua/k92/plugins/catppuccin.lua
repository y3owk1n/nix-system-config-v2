---@type LazySpec
return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    ---@type CatppuccinOptions
    opts = {
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
        fidget = true,
        snacks = {
          enabled = true,
        },
        which_key = true,
      },
    },
    config = function(_, opts)
      local colors = require("catppuccin.palettes").get_palette()
      local c_utils = require("catppuccin.utils.colors")

      opts.custom_highlights = {
        --- for `blink_cmp`
        --- override to match `float.transparent` settings
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
      }

      require("catppuccin").setup(opts)

      vim.cmd.colorscheme("catppuccin-macchiato")
    end,
  },
}
