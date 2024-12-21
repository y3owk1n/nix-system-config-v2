-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

vim.opt.mouse = ""

vim.opt.colorcolumn = "120" -- make width to 80

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
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

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

vim.opt.wrap = false

-- Minimal number of screen lines to keep above and below the cursor.
-- vim.opt.scrolloff = 8

-- Remove tablines
vim.opt.showtabline = 0

vim.opt.synmaxcol = 300 -- Don't syntax highlight long lines

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
vim.opt.shortmess:append("I") -- don't show the default intro message
vim.opt.shortmess:append("A") -- Ignore swap file messages
vim.opt.shortmess:append({ s = true, I = true }) -- disable search count wrap and startup messages

vim.opt.viewoptions:remove("curdir") -- disable saving current directory with views

vim.opt.backspace:append({ "nostop" }) -- don't stop backspace at insert

vim.opt.whichwrap:append("<,>,[,],h,l")
