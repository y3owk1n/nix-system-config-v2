---@type PluginModule
local M = {}

M.name = "base16-pro-max"

M.priority = 1

M.registry = {
  { src = "https://github.com/y3owk1n/base16.nvim", name = "base16-pro-max" },
  -- { src = "local:base16-pro-max.nvim", name = "base16-pro-max" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "base16-pro-max")

  if not plugin_ok then
    return
  end

  local pastel_twilight =
    require("utils.base-16-colors").get_base16_colors("~/nix-system-config-v2/config/base16/pastel-twilight.yml")

  ---@type Base16ProMax.Config
  local plugin_opts = {
    colors = pastel_twilight,
    styles = {
      italic = true,
      bold = true,
    },
    plugins = {
      enable_all = true,
      lewis6991_gitsigns_nvim = false,
    },
    highlight_groups = {
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

  vim.cmd.colorscheme("base16-pro-max")
end

return M
