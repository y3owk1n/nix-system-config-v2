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
vim.keymap.set("n", "<leader>sr", ":copen<cr>", { desc = "Resume qf list" })
vim.keymap.set("n", "<leader>st", function()
  fuzzy_search.grep({ "TODO", "FIXME", "HACK" })
end, { desc = "Grep TODOs" })

-- =========================================================
--  Notifier
-- =========================================================

local notifier = require("notifier")

notifier.setup({
  border = "rounded",
  padding = { left = 1, right = 1 },
  animation = {
    enabled = true,
  },
})

vim.keymap.set("n", "<leader>N", function()
  notifier.show_history()
end, { desc = "Show Notification History" })
vim.keymap.set("n", "<leader>un", function()
  notifier.dismiss_all()
end, { desc = "Dismiss All Notifications" })

local old_laststatus = vim.o.laststatus
local old_cmdheight = vim.o.cmdheight

vim.api.nvim_create_autocmd("OptionSet", {
  callback = function()
    local new_laststatus = vim.o.laststatus
    local new_cmdheight = vim.o.cmdheight

    if new_laststatus ~= old_laststatus or new_cmdheight ~= old_cmdheight then
      old_laststatus = new_laststatus
      old_cmdheight = new_cmdheight

      -- let the plugin recalculate positions
      notifier._internal.utils.cache_config_group_row_col()
    end
  end,
})

-- =========================================================
--  Undo glow
-- =========================================================

local undo_glow = require("undo-glow")

undo_glow.setup({
  animation = {
    enabled = true,
    duration = 300,
    window_scoped = true,
  },
  priority = 2048 * 3,
})

local api = require("undo-glow.api")

api.register_hook("pre_animation", function(data)
  local search = { "search_next", "search_prev", "search_star", "search_hash" }

  if vim.tbl_contains(search, data.operation) then
    data.animation_type = "strobe"
  elseif data.operation == "cursor_moved" then
    data.animation_type = "slide"
  elseif data.operation == "search_cmd" then
    data.animation_type = "fade"
  end
end, 75)

local function preserve_cursor()
  local pos = vim.fn.getpos(".")

  vim.schedule(function()
    vim.g.ug_ignore_cursor_moved = true
    vim.fn.setpos(".", pos)
  end)
end

vim.keymap.set("n", "u", function()
  undo_glow.undo()
end, { desc = "Undo with highlight", noremap = true })

vim.keymap.set("n", "U", function()
  undo_glow.redo()
end, { desc = "Redo with highlight", noremap = true })

vim.keymap.set("n", "p", function()
  undo_glow.paste_below()
end, { desc = "Paste below with highlight", noremap = true })

vim.keymap.set("n", "P", function()
  undo_glow.paste_above()
end, { desc = "Paste above with highlight", noremap = true })

vim.keymap.set("n", "n", function()
  undo_glow.search_next()
end, { desc = "Search next with highlight", noremap = true })

vim.keymap.set("n", "N", function()
  undo_glow.search_prev()
end, { desc = "Search prev with highlight", noremap = true })

vim.keymap.set("n", "*", function()
  undo_glow.search_star()
end, { desc = "Search star with highlight", noremap = true })

vim.keymap.set("n", "#", function()
  undo_glow.search_hash()
end, { desc = "Search hash with highlight", noremap = true })

vim.keymap.set({ "n", "x" }, "gc", function()
  preserve_cursor()
  return undo_glow.comment()
end, { desc = "Toggle comment with highlight", noremap = true, expr = true })

vim.keymap.set("o", "gc", function()
  undo_glow.comment_textobject()
end, { desc = "Toggle textobject with highlight", noremap = true })

vim.keymap.set("n", "gcc", function()
  return undo_glow.comment_line()
end, { desc = "Toggle comment line with highlight", noremap = true, expr = true })

local augroup = vim.api.nvim_create_augroup("UndoGlow", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  desc = "Highlight when yanking (copying) text",
  callback = function()
    undo_glow.yank()
  end,
})

-- This only handles neovim instance and do not highlight when switching panes in tmux
vim.api.nvim_create_autocmd("CursorMoved", {
  group = augroup,
  desc = "Highlight when cursor moved significantly",
  callback = function()
    undo_glow.cursor_moved()
  end,
})

-- This will handle highlights when focus gained, including switching panes in tmux
vim.api.nvim_create_autocmd("FocusGained", {
  group = augroup,
  desc = "Highlight when focus gained",
  callback = function()
    local opts = {
      animation = {
        animation_type = "slide",
      },
    }

    opts = require("undo-glow.utils").merge_command_opts("UgCursor", opts)
    local pos = require("undo-glow.utils").get_current_cursor_row()

    undo_glow.highlight_region(vim.tbl_extend("force", opts, {
      s_row = pos.s_row,
      s_col = pos.s_col,
      e_row = pos.e_row,
      e_col = pos.e_col,
      force_edge = opts.force_edge == nil and true or opts.force_edge,
    }))
  end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = augroup,
  desc = "Highlight when search cmdline leave",
  callback = function()
    undo_glow.search_cmd()
  end,
})
