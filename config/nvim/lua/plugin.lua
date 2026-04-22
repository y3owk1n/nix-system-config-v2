-- =========================================================
--  Tmux Navigation
-- =========================================================

local nvim_tmux_navigation = require("nvim-tmux-navigation")

nvim_tmux_navigation.setup({})

vim.keymap.set("n", "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>", { desc = "Navigate left" })
vim.keymap.set("n", "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>", { desc = "Navigate down" })
vim.keymap.set("n", "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>", { desc = "Navigate up" })
vim.keymap.set("n", "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>", { desc = "Navigate right" })

-- =========================================================
--  Formatting
-- =========================================================

local conform = require("conform")

conform.setup({
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
--  AI completions
-- =========================================================

local supermaven = require("supermaven-nvim")

supermaven.setup({
  keymaps = {
    accept_suggestion = "<C-y>",
  },
  ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
})

-- =========================================================
--  Treesitter
-- =========================================================

local nvim_treesitter = require("nvim-treesitter")

nvim_treesitter.install({
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

local mini_files = require("mini.files")
local mini_files_git = require("custom.mini-files-git")

mini_files.setup({
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

mini_files_git.setup()

vim.keymap.set("n", "<leader>e", function()
  if not mini_files.close() then
    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path == "" or not vim.uv.fs_stat(buf_path) then
      buf_path = vim.uv.cwd() or ""
    end
    mini_files.open(buf_path, true)
  end
end, { desc = "Explorer (buffer path)" })

vim.keymap.set("n", "<leader>E", function()
  if not mini_files.close() then
    mini_files.open(vim.uv.cwd(), true)
  end
end, { desc = "Explorer (cwd)" })

-- =========================================================
--  Git Diff
-- =========================================================

local mini_diff = require("mini.diff")

mini_diff.setup({
  view = {
    style = "sign",
    signs = {
      add = "▎",
      change = "▎",
      delete = "",
    },
  },
})

vim.keymap.set("n", "<leader>gd", function()
  mini_diff.toggle_overlay(0)
end, { desc = "Toggle diff overlay" })

-- =========================================================
--  Icons
-- =========================================================

local mini_icons = require("mini.icons")

mini_icons.setup({
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

mini_icons.mock_nvim_web_devicons()

-- =========================================================
--  Better restart
-- =========================================================

local restart = require("custom.restart")

restart.setup()

vim.keymap.set("n", "<leader>R", function()
  restart.save_restart()
end, { desc = "Save and restart" })

-- =========================================================
--  LSP Rename
-- =========================================================

local lsp_rename = require("custom.lsp-rename")

lsp_rename.setup()

-- =========================================================
--  Bigfile
-- =========================================================

local bigfile = require("custom.bigfile")

bigfile.setup()

-- =========================================================
--  Markdown utils
-- =========================================================

local markdown_utils = require("custom.markdown-utils")

markdown_utils.setup()

vim.keymap.set("n", "<leader>cc", markdown_utils.toggle_markdown_checkbox, { desc = "Toggle markdown checkbox" })
vim.keymap.set("n", "<leader>cgC", markdown_utils.insert_markdown_checkbox, { desc = "Insert markdown checkbox" })
vim.keymap.set("n", "<leader>cgc", markdown_utils.insert_markdown_checkbox_below, { desc = "Insert checkbox below" })

-- =========================================================
--  Fuzzy search
-- =========================================================

local fuzzy_search = require("custom.fuzzy-search")

fuzzy_search.setup({
  grep_flags = { "--smart-case" },
})

vim.keymap.set("n", "<leader><leader>", ":find<space>", { desc = "Fuzzy find files" })
vim.keymap.set("n", "<leader>sh", ":help<space>", { desc = "Fuzzy find help" })
vim.keymap.set("n", "<leader>sH", ":highlight<space>", { desc = "Fuzzy find highlight" })
vim.keymap.set("n", "<leader>sk", ":map<space>", { desc = "Fuzzy find keymaps" })

vim.keymap.set("n", "<leader>sf", fuzzy_search.files, { desc = "Files fuzzy" })
vim.keymap.set("n", "<leader>sg", fuzzy_search.grep, { desc = "Grep text" })
vim.keymap.set("n", "<leader>sw", function()
  fuzzy_search.grep(vim.fn.expand("<cword>"))
end, { desc = "Grep word" })
vim.keymap.set("n", "<leader>sr", fuzzy_search.grep_last, { desc = "Grep repeat" })
vim.keymap.set("n", "<leader>st", function()
  fuzzy_search.grep({ "TODO", "FIXME", "HACK" })
end, { desc = "Grep TODOs" })
