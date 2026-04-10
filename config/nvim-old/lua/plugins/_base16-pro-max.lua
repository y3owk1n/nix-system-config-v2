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

  local yaml_parser = require("base16-pro-max.parser")

  ---@type Base16ProMax.Config
  local plugin_opts = {
    colors = yaml_parser.get_base16_colors("~/nix-system-config-v2/config/pastel-twilight/base16.yml"),
    styles = {
      italic = true,
      bold = true,
    },
    plugins = {
      enable_all = true,
      lewis6991_gitsigns_nvim = false,
      folke_flash_nvim = false,
      nvim_telescope_telescope_nvim = false,
      ibhagwan_fzf_lua = false,
      nvim_lualine_lualine_nvim = false,
    },
    highlight_groups = {
      -- mini.nvim
      MiniIndentscopeSymbol = { fg = "orange" },
      -- mini.statusline
      MiniStatuslineFilename = { fg = "yellow" },
      MiniStatuslineModeNormal = { fg = "blue", bg = "blue", blend = 20, bold = true },
      MiniStatuslineModeInsert = { fg = "green", bg = "green", blend = 20, bold = true },
      MiniStatuslineModeVisual = { fg = "yellow", bg = "yellow", blend = 20, bold = true },
      MiniStatuslineModeReplace = { fg = "cyan", bg = "cyan", blend = 20, bold = true },
      MiniStatuslineModeCommand = { fg = "red", bg = "red", blend = 20, bold = true },
      MiniStatuslineModeOther = { fg = "brown", bg = "brown", blend = 20, bold = true },
    },
  }

  plugin.setup(plugin_opts)

  vim.cmd.colorscheme("base16-pro-max")
end

return M
