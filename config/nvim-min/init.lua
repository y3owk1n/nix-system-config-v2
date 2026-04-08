-- =========================================================
--  Neovim Configuration (init.lua)
-- =========================================================
--  Philosophy:
--    - Native-first (no heavy plugin manager)
--    - Quickfix-driven workflows
--    - Minimal but powerful
-- =========================================================

-- =========================================================
--  Plugins (vim.pack)
-- =========================================================
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/brenoprata10/nvim-highlight-colors",
  "https://github.com/y3owk1n/base16-pro-max.nvim",
  "https://github.com/alexghergh/nvim-tmux-navigation",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/laytan/cloak.nvim",
  "https://github.com/mfussenegger/nvim-lint",
  "https://github.com/supermaven-inc/supermaven-nvim",
  "https://github.com/nvim-mini/mini.files",
})

-- Built-in / optional plugins
vim.cmd.packadd("cfilter")
vim.cmd.packadd("nvim.undotree")
vim.cmd.packadd("nvim.difftool")

-- =========================================================
--  Colorscheme
-- =========================================================
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

-- =========================================================
--  Core Options
-- =========================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI
vim.opt.termguicolors = true
vim.opt.colorcolumn = "120"
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.pumblend = 10
vim.opt.pumheight = 10
vim.opt.signcolumn = "yes"
vim.opt.winborder = "rounded"
vim.opt.fillchars = { eob = " " }

-- Window behavior
vim.opt.virtualedit = "block"
vim.opt.splitkeep = "screen"
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Input / completion
vim.opt.mouse = ""
vim.opt.inccommand = "split"
vim.opt.completeopt = "menu,menuone,fuzzy,noinsert"

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.smartindent = true
vim.opt.breakindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Files / undo
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- Misc
vim.opt.confirm = true
vim.opt.linebreak = true
vim.opt.wildoptions:append({ "fuzzy" })
vim.opt.path:append({ "**" })
vim.opt.grepprg = "rg --vimgrep --no-messages --smart-case"
vim.opt.statusline = "[%n] %<%f %h%w%m%r%=%-14.(%l,%c%V%) %P"

-- =========================================================
--  Clipboard (Cross-Environment Support)
-- =========================================================
vim.schedule(function()
  -- vim.opt.clipboard = "unnamedplus"

  local hostname = vim.uv.os_gethostname()

  if hostname == "nixos-orb" then
    -- Running inside OrbStack NixOS VM
    vim.g.clipboard = {
      name = "macOS-clipboard",
      copy = {
        ["+"] = "mac pbcopy",
        ["*"] = "mac pbcopy",
      },
      paste = {
        ["+"] = "mac pbpaste",
        ["*"] = "mac pbpaste",
      },
      cache_enabled = 0,
    }
  end

  vim.opt.clipboard = "unnamedplus"
end)

-- =========================================================
--  Syntax / Highlighting
-- =========================================================
-- Only highlight with treesitter
vim.cmd("syntax off")

-- =========================================================
--  Plugin Setup
-- =========================================================

-- Highlight hex colors
require("nvim-highlight-colors").setup({
  render = "virtual",
  virtual_symbol = "⚫︎",
  virtual_symbol_suffix = "",
})

-- tmux navigation
require("nvim-tmux-navigation").setup({})

-- Formatting (conform)
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

-- Secrets masking
require("cloak").setup({})

-- AI completion
require("supermaven-nvim").setup({
  keymaps = {
    accept_suggestion = "<C-y>",
  },
  ignore_filetypes = { "bigfile", "float_info", "minifiles", "minipick" },
})

-- Treesitter
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

-- Mini.files
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
  options = { use_as_default_explorer = true },
  content = { prefix = function() end },
})

vim.keymap.set("n", "<leader>e", function()
  if not require("mini.files").close() then
    local buf_path = vim.api.nvim_buf_get_name(0)
    if buf_path == "" or not vim.uv.fs_stat(buf_path) then
      buf_path = vim.uv.cwd() or ""
    end
    require("mini.files").open(buf_path, true)
  end
end, { desc = "Explorer (buffer path)" })

vim.keymap.set("n", "<leader>E", function()
  if not require("mini.files").close() then
    require("mini.files").open(vim.uv.cwd(), true)
  end
end, { desc = "Explorer (cwd)" })

-- =========================================================
--  Keymaps
-- =========================================================

-- tmux navigation
vim.keymap.set("n", "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>", { desc = "Navigate left" })
vim.keymap.set("n", "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>", { desc = "Navigate down" })
vim.keymap.set("n", "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>", { desc = "Navigate up" })
vim.keymap.set("n", "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>", { desc = "Navigate right" })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", function()
  if vim.v.hlsearch == 1 then
    vim.cmd("nohlsearch")
  else
    return "<Esc>"
  end
end, { expr = true })

-- Arglist helpers
vim.keymap.set("n", "<leader>ha", function()
  vim.cmd("$argadd %")
  vim.cmd("argdedup")
end)

vim.keymap.set("n", "<leader>he", function()
  local args = vim.fn.argv()
  local items = {}

  for _, file in ipairs(args) do
    table.insert(items, {
      filename = file,
      lnum = 1,
      text = file,
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "Arglist",
    items = items,
  })

  vim.cmd("copen")
end)

-- Arglist jump
for i = 1, 9 do
  vim.keymap.set("n", "<leader>" .. tostring(i), function()
    vim.cmd("silent! " .. tostring(i) .. "argument")
  end)
end

-- File search (rg)
vim.keymap.set("n", "<leader><leader>", function()
  local files = vim.fn.systemlist("rg --files")

  local items = {}
  for _, f in ipairs(files) do
    table.insert(items, {
      filename = f,
      lnum = 1,
      col = 1,
      text = f,
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "Files",
    items = items,
  })

  vim.cmd("copen")
end)

-- Grep
vim.keymap.set("n", "<leader>sg", function()
  local input = vim.fn.input("Grep > ")
  if input == "" then
    return
  end

  local cmd = "rg --vimgrep " .. vim.fn.shellescape(input)

  vim.fn.setqflist({}, " ", {
    title = "Grep: " .. input,
    lines = vim.fn.systemlist(cmd),
  })

  vim.cmd("copen")
end)

-- Git find
vim.keymap.set("n", "<leader>gf", function()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if not root or root == "" then
    print("Not in a git repo")
    return
  end

  -- Collect files from all states
  local staged = vim.fn.systemlist("git diff --cached --name-only")
  local unstaged = vim.fn.systemlist("git diff --name-only")
  local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")

  -- Merge + deduplicate
  local seen = {}
  local all_files = {}

  local function add(files)
    for _, f in ipairs(files) do
      if f ~= "" and not seen[f] then
        seen[f] = true
        table.insert(all_files, f)
      end
    end
  end

  add(staged)
  add(unstaged)
  add(untracked)

  -- Build quickfix items
  local items = {}
  for _, f in ipairs(all_files) do
    table.insert(items, {
      filename = root .. "/" .. f,
      lnum = 1,
      text = f,
    })
  end

  vim.fn.setqflist({}, " ", {
    title = "Git Files (All)",
    items = items,
  })

  vim.cmd("copen")
end)

-- Movement enhancements
vim.keymap.set({ "n", "v" }, "H", "^")
vim.keymap.set({ "n", "v" }, "L", "$")

vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Visual indent
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Splits
vim.keymap.set("n", "-", "<C-W>s", { remap = true })
vim.keymap.set("n", "\\", "<C-W>v", { remap = true })

-- Misc
vim.keymap.set("n", "<C-a>", "gg<S-v>G")
vim.keymap.set("n", "x", '"_x')

vim.keymap.set("v", "J", ":m '>+1<cr> | :normal gv=gv<cr>")
vim.keymap.set("v", "K", ":m '<-2<cr> | :normal gv=gv<cr>")

vim.keymap.set({ "n", "x" }, "Q", "<nop>")

-- LSP keymaps
vim.keymap.set("n", "grd", vim.lsp.buf.definition)
vim.keymap.set("n", "grr", vim.lsp.buf.references)
vim.keymap.set("n", "gri", vim.lsp.buf.implementation)
vim.keymap.set("n", "grt", vim.lsp.buf.type_definition)
vim.keymap.set("n", "grs", vim.lsp.buf.document_symbol)

-- =========================================================
--  Autocommands
-- =========================================================
local function augroup(name)
  return vim.api.nvim_create_augroup("k92_" .. name, { clear = true })
end

-- Treesitter
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter"),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- LSP attach
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lsp"),
  callback = function(args)
    vim.o.signcolumn = "yes:1"
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method("textDocument/completion") then
      vim.o.complete = "o,.,w,b,u"
      vim.o.completeopt = "menu,menuone,popup,noinsert"

      vim.lsp.completion.enable(true, client.id, args.buf, {
        autotrigger = true,
        convert = function(item)
          return { abbr = item.label:gsub("%b()", "") }
        end,
      })
    end
  end,
})

-- Yank highlight
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("text_yank_post"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Quickfix enter behavior
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("file_type_qf"),
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>:cclose<CR>", { buffer = true })
  end,
})

-- Lint
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = augroup("lint"),
  callback = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      dockerfile = { "hadolint" },
      fish = { "fish" },
      go = { "golangcilint" },
      markdown = { "markdownlint-cli2" },
      ["markdown.mdx"] = { "markdownlint-cli2" },
    }

    local linters = lint.linters_by_ft[vim.bo.filetype]
    lint.try_lint(linters)
  end,
})

-- Close with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "checkhealth",
    "dbout",
    "grug-far",
    "help",
    "qf",
    "startuptime",
    "tsplayground",
    "mininotify-history",
    "lspinfo",
    "lsplog",
    "lintinfo",
    "cmd",
    "nvim-pack",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false

    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true })
    end)
  end,
})

-- Trim whitespace
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("remove_whitespace_on_save"),
  command = ":%s/\\s\\+$//e",
})

-- Disable auto comment
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("no_auto_commeting_new_lines"),
  command = "set fo-=c fo-=r fo-=o",
})

-- Auto reload
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Resize splits
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Help to the right
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("split_help_right"),
  pattern = "help",
  command = "wincmd L",
})

-- Pack changed
vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup("pack_changed"),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind

    -- run TSUpdate when nvim-treesitter is updated
    if name == "nvim-treesitter" and kind == "update" then
      vim.cmd("TSUpdate")
    end
  end,
})

-- =========================================================
--  Diagnostics
-- =========================================================
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = {
    prefix = "",
    suffix = "",
    format = function(diagnostic)
      local icon = vim.diagnostic.config().signs.text[diagnostic.severity]
      if icon then
        return string.format("%s %s ", icon, diagnostic.message)
      else
        return diagnostic.message
      end
    end,
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
      [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
    },
  },
  float = {
    source = true,
    severity_sort = true,
  },
})

-- =========================================================
--  LSP Configuration
-- =========================================================
vim.lsp.enable({
  "bashls",
  "biome",
  "clangd",
  "docker_language_server",
  "docker_compose_language_service",
  "eslint",
  "gh_actions_ls",
  "gopls",
  "jsonls",
  "just",
  "lua_ls",
  "marksman",
  "nixd",
  "prismals",
  "rust_analyzer",
  "tailwindcss",
  "vtsls",
  "yamlls",
})

vim.lsp.config("just", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      completion = { enable = true },
      diagnostics = {
        enable = true,
        globals = { "vim" },
      },
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
    },
  },
})
