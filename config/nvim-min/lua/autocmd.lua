---Create an augroup
---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("k92_" .. name, { clear = true })
end

-- =========================================================
--  Start Treesitter
-- =========================================================
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter"),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- =========================================================
--  LSP attached with actions
-- =========================================================
vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup("lsp"),
  callback = function(args)
    local bufnr = args.buf

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

    -- rename filename
    vim.keymap.set("n", "<leader>cr", function()
      require("custom.lsp-rename").rename_file()
    end, { buffer = bufnr, desc = "Rename file" })

    -- lsp thingy (the rest are already included by neovim default)
    vim.keymap.set("n", "grd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
  end,
})

-- =========================================================
--  Yank highlight
-- =========================================================
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("text_yank_post"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- =========================================================
--  Close quickfix window on enter
-- =========================================================
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("file_type_qf"),
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "<CR>", "<CR>:cclose<CR>", { buffer = true })
  end,
})

-- =========================================================
--  Lint with nvim-lint
-- =========================================================
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

-- =========================================================
--  Close with q key
-- =========================================================
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

-- =========================================================
--  Trim whitespace on save
-- =========================================================
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("remove_whitespace_on_save"),
  command = ":%s/\\s\\+$//e",
})

-- =========================================================
--  Disable auto commenting new lines
-- =========================================================
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("no_auto_commeting_new_lines"),
  command = "set fo-=c fo-=r fo-=o",
})

-- =========================================================
--  Auto reload when file changed
-- =========================================================
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- =========================================================
--  Resize splits
-- =========================================================
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- =========================================================
--  Move help to the right split
-- =========================================================
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("split_help_right"),
  pattern = "help",
  command = "wincmd L",
})

-- =========================================================
--  Do something when vim.pack updates
-- =========================================================
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
--  Trigger fuzzy finder
-- =========================================================
local function is_cmdline_type_find()
  local cmdline_cmd = vim.fn.split(vim.fn.getcmdline(), " ")[1]

  return cmdline_cmd == "find" or cmdline_cmd == "fin"
end

vim.api.nvim_create_autocmd({ "CmdlineChanged", "CmdlineLeave" }, {
  pattern = { "*" },
  group = augroup("CmdlineAutocompletion"),
  callback = function(ev)
    local function should_enable_autocomplete()
      local cmdline_cmd = vim.fn.split(vim.fn.getcmdline(), " ")[1]

      return is_cmdline_type_find() or cmdline_cmd == "help" or cmdline_cmd == "h"
    end

    if ev.event == "CmdlineChanged" and should_enable_autocomplete() then
      vim.opt.wildmode = "noselect:lastused,full"
      vim.fn.wildtrigger()
    end

    if ev.event == "CmdlineLeave" then
      vim.opt.wildmode = "full"
    end
  end,
})
