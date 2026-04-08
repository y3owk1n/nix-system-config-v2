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
  },
})

vim.cmd.colorscheme("base16-pro-max")
