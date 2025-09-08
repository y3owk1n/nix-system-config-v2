---@type PluginModule
local M = {}

M.name = "base16"

M.priority = 1

-- M.enabled = false

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/base16", name = "base16" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "base16")

  if not plugin_ok then
    return
  end

  local rose_pine_moon = {
    base00 = "#232136",
    base01 = "#2a273f",
    base02 = "#393552",
    base03 = "#6e6a86",
    base04 = "#908caa",
    base05 = "#e0def4",
    base06 = "#e0def4",
    base07 = "#56526e",
    base08 = "#eb6f92",
    base09 = "#ea9a97",
    base0A = "#f6c177",
    base0B = "#95b1ac",
    base0C = "#9ccfd8",
    base0D = "#3e8fb0",
    base0E = "#c4a7e7",
    base0F = "#56526e",
  }

  ---@type Base16.Config
  local plugin_opts = {
    colors = rose_pine_moon,
    enable_bold = true,
    enable_italics = true,
    enable_transparency = true,
    highlight_groups = {
      -- status line colors
      StatusLine = { fg = "fg_dark", bg = "bg_dim" },
      -- barline
      BarlineFileInfo = { fg = "yellow" }, -- match my tmux layout
      BarlineDiagnosticError = { link = "DiagnosticError" },
      BarlineDiagnosticWarn = { link = "DiagnosticWarn" },
      BarlineDiagnosticInfo = { link = "DiagnosticInfo" },
      BarlineDiagnosticHint = { link = "DiagnosticHint" },
      -- time machine colors
      TimeMachineCurrent = {
        bg = "cyan",
        blend = 15,
      },
      TimeMachineTimeline = { fg = "purple" },
      TimeMachineTimelineAlt = { fg = "fg_dark" },
      TimeMachineKeymap = { fg = "cyan" },
      TimeMachineSeq = { fg = "yellow" },
      TimeMachineTag = { fg = "green" },
      -- mini.nvim
      MiniIndentscopeSymbol = { fg = "orange" },
    },
  }

  plugin.setup(plugin_opts)

  plugin.load()
end

return M
