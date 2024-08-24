-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt
vim.g.maplocalleader = ","

--shell
opt.shell = "fish"

-- Lazygit
vim.g.lazygit_config = false

-- encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
vim.scriptencoding = "utf-8"

-- Width
opt.colorcolumn = "80" -- make width to 80

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 4 -- 4 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 4 spaces for indent width
opt.softtabstop = 4 -- 4 spaces for softtab
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
opt.breakindent = true

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive
opt.hlsearch = false -- do not highlight search
opt.incsearch = true -- follow the searches

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- scroll
opt.scrolloff = 8 -- set scroll offset to maximum lines (will always be in middle)

-- mouse
opt.mouse = ""

-- undo
opt.undofile = true
opt.undolevels = 10000
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- turn off swapfile
opt.swapfile = false
opt.updatetime = 50 -- Save swap file and trigger CursorHold

-- words
opt.path:append("**")
opt.iskeyword:append("-") -- consider string-string as whole words
opt.isfname:append("@-@")
opt.fillchars = {
	foldopen = "",
	foldclose = "",
	-- fold = "⸱",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}

-- enable undercurl
vim.cmd([[let &t_Cs = "\e[4:3m]"]])
vim.cmd([[let &t_Ce = "\e[4:0m]"]])

-- Add astericks in block comments
opt.formatoptions:append({ "r" })

opt.spelllang:append("cjk") -- disable spellchecking for asian characters (VIM algorithm does not support it)
opt.shortmess:append("c") -- don't show redundant messages from ins-completion-menu
opt.shortmess:append("I") -- don't show the default intro message
opt.shortmess:append({ s = true, I = true }) -- disable search count wrap and startup messages

opt.viewoptions:remove("curdir") -- disable saving current directory with views

opt.backspace:append({ "nostop" }) -- don't stop backspace at insert

opt.whichwrap:append("<,>,[,],h,l")

-- Add border for lsp diagnostics
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end
