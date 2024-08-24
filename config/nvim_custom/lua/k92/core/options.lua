local opt = vim.opt -- for conciseness
local global = vim.g
local cmd = vim.cmd

-- disable some extension providers
global.loaded_python3_provider = 0
global.loaded_ruby_provider = 0
global.loaded_node_provider = 0
global.loaded_perl_provider = 0

-- encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
vim.scriptencoding = "utf-8"

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- Width
opt.colorcolumn = "80" -- make width to 80

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

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom
opt.splitkeep = "cursor"

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
opt.wildignore:append("**/node_modules/**")

-- enable undercurl
cmd([[let &t_Cs = "\e[4:3m]"]])
cmd([[let &t_Ce = "\e[4:0m]"]])

-- Add astericks in block comments
opt.formatoptions:append({ "r" })

opt.laststatus = 3 -- global statusline
opt.spelllang:append("cjk") -- disable spellchecking for asian characters (VIM algorithm does not support it)
opt.shortmess:append("c") -- don't show redundant messages from ins-completion-menu
opt.shortmess:append("I") -- don't show the default intro message
opt.shortmess:append({ s = true, I = true }) -- disable search count wrap and startup messages

opt.viewoptions:remove("curdir") -- disable saving current directory with views

---@diagnostic disable-next-line: undefined-field
opt.backspace:append({ "nostop" }) -- don't stop backspace at insert

opt.whichwrap:append("<,>,[,],h,l")

opt.cmdheight = 0

-- Add border
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "rounded"
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end
