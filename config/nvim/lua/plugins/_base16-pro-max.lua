---@type PluginModule
local M = {}

M.name = "base16-pro-max"

M.priority = 1

M.registry = {
  { src = "https://github.com/y3owk1n/base16-pro-max.nvim", name = "base16-pro-max" },
  -- { src = "local:base16-pro-max.nvim", name = "base16-pro-max" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "base16-pro-max")

  if not plugin_ok then
    return
  end

  local pastel_twilight = {
    base00 = "#1f1d2e",
    base01 = "#2a2738",
    base02 = "#3a364d",
    base03 = "#5a5672",
    base04 = "#9a96b5",
    base05 = "#e0def4",
    base06 = "#f0ecf9",
    base07 = "#faf7ff",
    base08 = "#f28fad",
    base09 = "#f8bd96",
    base0A = "#f9e2af",
    base0B = "#abe9b3",
    base0C = "#b5e8e0",
    base0D = "#80b8e8",
    base0E = "#c9a0e9",
    base0F = "#d4a4b8",
  }

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
      folke_flash_nvim = false,
    },
    highlight_groups = {
      -- barline
      BarlineFileInfo = { fg = "yellow" }, -- match my tmux layout
      BarlineDiagnosticError = { link = "DiagnosticError" },
      BarlineDiagnosticWarn = { link = "DiagnosticWarn" },
      BarlineDiagnosticInfo = { link = "DiagnosticInfo" },
      BarlineDiagnosticHint = { link = "DiagnosticHint" },
      -- mini.nvim
      MiniIndentscopeSymbol = { fg = "orange" },
    },
  }

  plugin.setup(plugin_opts)

  vim.cmd.colorscheme("base16-pro-max")
end

return M
