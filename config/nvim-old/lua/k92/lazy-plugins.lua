---@diagnostic disable: missing-fields
require("lazy").setup({
  { import = "k92.plugins" },
}, {
  defaults = {
    lazy = true,
    version = false, -- always use the latest git commit
  },
  checker = { enabled = true, notify = false }, -- automatically check for plugin updates
  change_detection = {
    enabled = false,
  },
  ui = {
    border = "rounded",
    backdrop = 100,
  },
  install = {
    colorscheme = {},
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "2html_plugin",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
})
