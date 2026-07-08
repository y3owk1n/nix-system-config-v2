-- =========================================================
--  My amazing base16 theme colorscheme
--  I am currently using stylix with my preferred colorscheme
--  on nix, so it's nice to have this here for consistency
-- =========================================================

require("base16-pro-max").setup({
  colors = require("base16-pro-max.parser").get_base16_colors("~/.config/stylix/palette.json"),
  styles = {
    italic = true,
    bold = true,
  },
  plugins = {
    enable_all = false,
    nvim_mini_mini_diff = true,
    nvim_mini_mini_icons = true,
    y3owk1n_undo_glow_nvim = true,
    magicduck_grug_far_nvim = true,
  },
  highlight_groups = {
    QuickFixLine = { fg = "red" },
    PmenuBorder = { link = "FloatBorder" },
  },
})

vim.cmd.colorscheme("base16-pro-max")
