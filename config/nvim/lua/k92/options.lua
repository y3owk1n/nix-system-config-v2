vim.opt.termguicolors = true

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Disable mouse
vim.opt.mouse = ""

vim.opt.colorcolumn = "120" -- make width to 80

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

vim.opt.ruler = false -- Don't show cursor position in command line

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- tabs & indentation
vim.opt.tabstop = 4 -- 2 spaces for tabs (prettier default)
vim.opt.shiftwidth = 4 -- 2 spaces for indent width
vim.opt.softtabstop = 4 -- 2 spaces for softtab
vim.opt.expandtab = false -- expand tab to spaces
vim.opt.autoindent = true -- copy indent from current line when starting new one

-- Enable break indent
vim.opt.breakindent = true

vim.opt.smartindent = true -- Make indenting smart

-- Save undo history
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.opt.swapfile = false
vim.opt.updatetime = 50 -- Save swap file and trigger CursorHold

vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true -- Infer letter cases for a richer built-in keyword completion
vim.opt.hlsearch = false -- do not highlight search
vim.opt.incsearch = true -- follow the searches

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.splitkeep = "screen" -- Reduce scroll during window split

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

vim.opt.wrap = false

vim.opt.linebreak = true -- Wrap long lines at 'breakat' (if 'wrap' is set)

-- Minimal number of screen lines to keep above and below the cursor.
-- vim.opt.scrolloff = 8

-- Remove tablines
vim.opt.showtabline = 0

vim.opt.synmaxcol = 300 -- Don't syntax highlight long lines

vim.opt.virtualedit = "block" -- Allow going past the end of line in visual block mode

-- words
vim.opt.path:append("**")
vim.opt.iskeyword:append("-") -- consider string-string as whole words
vim.opt.isfname:append("@-@")
vim.opt.fillchars = {
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
vim.opt.formatoptions:append({ "r" })

vim.opt.spelllang:append("cjk") -- disable spellchecking for asian characters (VIM algorithm does not support it)
vim.opt.shortmess:append("c") -- don't show redundant messages from ins-completion-menu
vim.opt.shortmess:append("A") -- Ignore swap file messages
vim.opt.shortmess:append("WcC") -- Reduce command line messages
vim.opt.shortmess:append({ s = true, I = true }) -- disable search count wrap and startup messages

vim.opt.viewoptions:remove("curdir") -- disable saving current directory with views

vim.opt.backspace:append({ "nostop" }) -- don't stop backspace at insert

vim.opt.whichwrap:append("<,>,[,],h,l")

vim.cmd("filetype plugin indent on") -- Enable all filetype plugins

-- Enable syntax highlighting if it wasn't already (as it is time consuming)
if vim.fn.exists("syntax_on") ~= 1 then
	vim.cmd([[syntax enable]])
end
