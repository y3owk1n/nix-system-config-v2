require("base16-pro-max").setup({
  colors = require("base16-pro-max.parser").get_base16_colors(
    "~/nix-system-config-v2/config/pastel-twilight/base16.yml"
  ),
  styles = {
    italic = true,
    bold = true,
  },
  plugins = {
    enable_all = false,
    nvim_mini_mini_diff = true,
    nvim_mini_mini_icons = true,
    nvim_mini_mini_files = true,
    y3owk1n_undo_glow_nvim = true,
  },
  highlight_groups = {
    QuickFixLine = { fg = "red" },
    PmenuBorder = { link = "FloatBorder" },
  },
})

vim.cmd.colorscheme("base16-pro-max")
