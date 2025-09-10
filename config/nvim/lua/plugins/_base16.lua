---@type PluginModule
local M = {}

M.name = "base16"

M.priority = 1

M.registry = {
  { src = vim.fn.stdpath("config") .. "/lua/custom-plugins/base16", name = "base16" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "base16")

  if not plugin_ok then
    return
  end

  local pastel_twilight =
    require("utils.base-16-colors").get_base16_colors("~/nix-system-config-v2/config/base16/pastel-twilight.yml")

  ---@type Base16.Config
  local plugin_opts = {
    colors = pastel_twilight,
    styles = {
      italic = true,
      bold = true,
      use_cterm = true,
    },
    plugins = {
      enable_all = true,
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

  vim.cmd.colorscheme("base16")
end

return M
