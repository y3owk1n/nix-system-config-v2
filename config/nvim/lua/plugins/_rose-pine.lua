---@type PluginModule
local M = {}

M.name = "rose-pine"

M.priority = 1

M.enabled = false

M.registry = {
  { src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "rose-pine")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
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
      ["@constructor"] = { fg = "muted" },
      -- status line colors
      StatusLine = { fg = "subtle", bg = "surface" },
      StatusLineNC = { fg = "subtle", bg = "_nc" },
      StatusLineTerm = { link = "StatusLine" },
      StatusLineTermNC = { link = "StatusLineNC" },
      -- barline
      BarlineFileInfo = { fg = "rose" }, -- match my tmux layout
      BarlineDiagnosticError = { link = "DiagnosticError" },
      BarlineDiagnosticWarn = { link = "DiagnosticWarn" },
      BarlineDiagnosticInfo = { link = "DiagnosticInfo" },
      BarlineDiagnosticHint = { link = "DiagnosticHint" },
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
      -- mini.nvim
      MiniIndentscopeSymbol = { fg = "rose" },
    },
  }

  plugin.setup(plugin_opts)

  vim.cmd.colorscheme("rose-pine-moon")
end

return M
