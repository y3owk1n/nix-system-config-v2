---@type LazySpec
return {
  "rose-pine/neovim",
  lazy = false,
  name = "rose-pine",
  priority = 1000,
  opts = {
    styles = {
      transparency = true,
    },

    -- NOTE: Highlight groups are extended (merged) by default. Disable this
    -- per group via `inherit = false`
    highlight_groups = {
      TimeMachineCurrent = {
        bg = "foam",
        blend = 15,
      },
      TimeMachineTimeline = { fg = "pine" },
      TimeMachineTimelineAlt = { fg = "overlay" },
      TimeMachineKeymap = { fg = "foam" },
      TimeMachineSeq = { fg = "rose" },
      TimeMachineTag = { fg = "gold" },
      StatusLine = { fg = "love", bg = "love", blend = 10 },
      StatusLineNC = { fg = "subtle", bg = "surface" },
    },
  },
  config = function(_, opts)
    local plugin = require("rose-pine")
    plugin.setup(opts)

    vim.cmd.colorscheme("rose-pine-moon")
  end,
}
