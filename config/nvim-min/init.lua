if vim.loader then
  vim.loader.enable()
end

require("pack")
require("colorscheme")
require("option")
require("plugin")
require("keymap")
require("autocmd")
require("diagnostic")
require("lsp")
