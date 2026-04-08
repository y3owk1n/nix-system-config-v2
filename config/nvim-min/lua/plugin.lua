-- =========================================================
--  Tmux Navigation
-- =========================================================
require("nvim-tmux-navigation").setup({})

-- =========================================================
--  Formatting
-- =========================================================
require("conform").setup({
  formatters_by_ft = {
    sh = { "shfmt" },
    fish = { "fish_indent" },
    javascript = { "biome", "prettierd", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", stop_after_first = true },
    typescript = { "biome", "prettierd", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", stop_after_first = true },
    json = { "biome", "prettierd", stop_after_first = true },
    jsonc = { "biome", "prettierd", stop_after_first = true },
    css = { "biome", "prettierd", stop_after_first = true },
    ["markdown"] = { "prettierd", "markdownlint-cli2" },
    ["markdown.mdx"] = { "prettierd", "markdownlint-cli2" },
    go = { "goimports", "gofumpt" },
    just = { "just" },
    lua = { "stylua" },
    nix = { "nixfmt" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})

-- =========================================================
--  Hide .env lines
-- =========================================================
require("cloak").setup({})

-- =========================================================
--  AI completions
-- =========================================================
require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<C-y>",
  },
  ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
})

-- =========================================================
--  Treesitter
-- =========================================================
require("nvim-treesitter").install({
  "html",
  "regex",
  "toml",
  "query",
  "vim",
  "vimdoc",
  "xml",
  "css",
  "kdl",
  "bash",
  "dockerfile",
  "fish",
  "git_config",
  "gitcommit",
  "git_rebase",
  "gitignore",
  "gitattributes",
  "go",
  "gomod",
  "gowork",
  "gosum",
  "json",
  "json5",
  "just",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "nix",
  "prisma",
  "javascript",
  "jsdoc",
  "tsx",
  "typescript",
  "yaml",
})

vim.filetype.add({
  pattern = {
    ["docker?-compose?.ya?ml"] = "yaml.docker-compose",
  },
})

vim.filetype.add({
  extension = { just = "just" },
  filename = {
    justfile = "just",
    Justfile = "just",
    [".Justfile"] = "just",
    [".justfile"] = "just",
  },
})

vim.filetype.add({
  extension = { mdx = "markdown.mdx" },
})

vim.treesitter.language.register("markdown", "markdown.mdx")

-- =========================================================
--  File Explorer
-- =========================================================
require("mini.files").setup({
  windows = {
    preview = true,
    width_focus = 30,
    width_preview = 60,
  },
  mappings = {
    close = "q",
    go_in = "",
    go_in_plus = "l",
    go_out = "",
    go_out_plus = "h",
    mark_goto = "'",
    mark_set = "m",
    reset = "<BS>",
    reveal_cwd = "@",
    show_help = "g?",
    synchronize = "=",
    trim_left = "<",
    trim_right = ">",
  },
})

require("custom.mini-files-git").setup()

-- =========================================================
--  Git Diff
-- =========================================================
require("mini.diff").setup({
  view = {
    style = "sign",
    signs = {
      add = "▎",
      change = "▎",
      delete = "",
    },
  },
})

-- =========================================================
--  Icons
-- =========================================================
require("mini.icons").setup({
  file = {
    [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
    ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
    [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
    [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
    [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
    [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
    [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
    ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
    ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
    ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
    ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
    ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
  },
  filetype = {
    dotenv = { glyph = "", hl = "MiniIconsYellow" },
    gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
  },
})

require("mini.icons").mock_nvim_web_devicons()

-- =========================================================
--  Better restart
-- =========================================================
require("custom.restart").setup()

-- =========================================================
--  Bigfile
-- =========================================================
require("custom.bigfile").setup()

-- =========================================================
--  Markdown utils
-- =========================================================
require("custom.markdown-utils").setup()
