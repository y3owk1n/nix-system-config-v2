---@type LazySpec
return {
  "rose-pine/neovim",
  enabled = true,
  lazy = false,
  name = "rose-pine",
  priority = 1000,
  opts = {
    dim_inactive_windows = true,

    styles = {
      transparency = true,
    },

    groups = {
      h1 = "love",
      h2 = "gold",
      h3 = "rose",
      h4 = "pine",
      h5 = "foam",
      h6 = "iris",
    },

    -- NOTE: Highlight groups are extended (merged) by default. Disable this
    -- per group via `inherit = false`
    highlight_groups = {
      -- general
      Normal = { bg = "base", fg = "text" },
      NormalFloat = { bg = "base", fg = "text" },
      -- status line colors
      StatusLine = { fg = "subtle", bg = "surface", bold = true },
      StatusLineNC = { fg = "subtle", bg = "_nc" },
      StatusLineTerm = { link = "StatusLine" },
      StatusLineTermNC = { link = "StatusLineNC" },
      -- time machine colors
      TimeMachineCurrent = {
        bg = "foam",
        blend = 15,
      },
      TimeMachineTimeline = { fg = "gold" },
      TimeMachineTimelineAlt = { fg = "muted" },
      TimeMachineKeymap = { fg = "foam" },
      TimeMachineSeq = { fg = "rose" },
      TimeMachineTag = { fg = "pine" },
      -- undo glow colors
      UgUndo = { bg = "love", blend = 30 },
      UgRedo = { bg = "pine", blend = 30 },
      UgYank = { bg = "gold", blend = 30 },
      UgPaste = { bg = "foam", blend = 30 },
      UgSearch = { bg = "iris", blend = 30 },
      UgComment = { bg = "rose", blend = 30 },
      UgCursor = { bg = "highlight_high" },
    },
  },
  config = function(_, opts)
    local plugin = require("rose-pine")
    plugin.setup(opts)

    vim.cmd.colorscheme("rose-pine-moon")
  end,
}
