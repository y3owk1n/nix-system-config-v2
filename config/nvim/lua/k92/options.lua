------------------------------------------------------------
-- UI & Visuals
------------------------------------------------------------
vim.opt.termguicolors = true -- Enable 24-bit RGB colors in the terminal.
vim.opt.colorcolumn = "120" -- Highlight column 120 to mark a visual guide.
vim.opt.cursorline = false -- Highlight the current cursor line.
vim.opt.wrap = false -- Disable line wrapping.
vim.opt.showmode = false -- Don't display the mode (e.g., INSERT, NORMAL).
vim.opt.ruler = false -- Do not show the cursor position in the command line.
vim.opt.pumblend = 10 -- Set blend level for pop-up menus.
vim.opt.pumheight = 10 -- Maximum number of entries in popup menus.
vim.opt.signcolumn = "yes" -- Always show the sign column for diagnostics or version control.
vim.opt.winborder = "rounded" -- Use rounded borders for floating windows.
vim.opt.synmaxcol = 300 -- Limit syntax highlighting to the first 300 columns.
vim.opt.fillchars = { -- Customize filler characters for various UI elements.
  foldopen = "", -- Icon for open fold.
  foldclose = "", -- Icon for closed fold.
  -- fold = "⸱",
  fold = " ", -- Filler for folds.
  foldsep = " ", -- Separator for folds.
  diff = "╱", -- Diff marker.
  eob = " ", -- End-of-buffer character (hides ~ symbols).
}
vim.opt.virtualedit = "block" -- Allow cursor to move past end-of-line in visual block mode.
vim.opt.splitkeep = "screen" -- Maintain screen view when splitting windows.
vim.opt.splitright = true -- Open vertical splits to the right.
vim.opt.splitbelow = true -- Open horizontal splits below.
vim.opt.showtabline = 0 -- Never show the tabline.
vim.opt.foldenable = false -- Do not enable folding by default.

------------------------------------------------------------
-- General Settings
------------------------------------------------------------
vim.opt.number = true -- Show absolute line numbers.
vim.opt.relativenumber = true -- Show relative line numbers.
vim.opt.mouse = "" -- Disable mouse support.
vim.opt.timeoutlen = 300 -- Set key sequence timeout to 300ms.
vim.opt.inccommand = "split" -- Show live preview of substitutions in a split.
vim.opt.completeopt = { "menu", "menuone", "noselect" } -- Configure completion menu behavior.
vim.opt.viewoptions:remove("curdir") -- Do not save the current directory with views.

------------------------------------------------------------
-- Text Editing Settings
------------------------------------------------------------
vim.opt.backspace:append({ "nostop" }) -- Allow backspace to delete over everything in insert mode.
vim.opt.whichwrap:append("<,>,[,],h,l") -- Enable cursor movement to wrap to previous/next line with specific keys.
vim.opt.formatoptions:append({ "r" }) -- Automatically insert comment leader after hitting <Enter> in comments.

------------------------------------------------------------
-- Tabs & Indentation
------------------------------------------------------------
--- these should be from my root editorconfig ---
-- vim.opt.tabstop = 2 -- Set tab width to 4 spaces.
-- vim.opt.shiftwidth = 2 -- Set indentation width to 4 spaces.
-- vim.opt.softtabstop = -1 -- Configure soft tab stop to 4 spaces.
--- these should be from my root editorconfig ---

vim.opt.expandtab = true -- Convert tabs into spaces.
vim.opt.shiftround = true -- Round indent to multiple of 'shiftwidth'.
vim.opt.smartindent = true -- Enable smart indentation.
vim.opt.breakindent = true -- Maintain indent on wrapped lines.

------------------------------------------------------------
-- Search Settings
------------------------------------------------------------
vim.opt.ignorecase = true -- Ignore case when searching.
vim.opt.smartcase = true -- Override 'ignorecase' if search contains uppercase.
vim.opt.infercase = true -- Adjust case for keyword completion.
vim.opt.hlsearch = false -- Do not highlight search matches.
vim.opt.incsearch = true -- Highlight matches as you type.

------------------------------------------------------------
-- File Handling & Sessions
------------------------------------------------------------
vim.opt.swapfile = false -- Disable swap file creation.
vim.opt.updatetime = 50 -- Reduce delay for CursorHold and swap file write.
vim.opt.undofile = true -- Enable persistent undo history.
vim.opt.undolevels = 10000 -- Set a high number of undo levels.
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir" -- Set custom undo directory.

------------------------------------------------------------
-- Clipboard Configuration
------------------------------------------------------------
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus" -- Sync system clipboard with Neovim.
end)

------------------------------------------------------------
-- Provider Configuration (Disable unused providers)
------------------------------------------------------------
vim.g.loaded_python3_provider = 0 -- Disable Python3 provider.
vim.g.loaded_perl_provider = 0 -- Disable Perl provider.
vim.g.loaded_ruby_provider = 0 -- Disable Ruby provider.
vim.g.loaded_node_provider = 0 -- Disable Node.js provider.

------------------------------------------------------------
-- Spelling & Keywords
------------------------------------------------------------
vim.opt.spelllang:append("cjk") -- Improve spellchecking for CJK languages.
vim.opt.iskeyword:append("-") -- Include '-' as part of a word.
vim.opt.isfname:append("@-@") -- Allow '@-@' in filenames.

------------------------------------------------------------
-- Wildmenu (Command Line Completion)
------------------------------------------------------------
vim.opt.wildmenu = true -- Enable command-line completion menu.
vim.opt.wildignorecase = true -- Make wildmenu file matching case-insensitive.
vim.opt.path:append("**") -- Enable recursive file searching.
vim.opt.wildignore:append({ -- Ignore certain file patterns in file navigation.
  ".git,.hg,.svn",
  ".aux,*.out,*.toc",
  ".o,*.obj,*.exe,*.dll,*.manifest,*.rbc,*.class",
  ".ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp",
  ".avi,*.divx,*.mp4,*.webm,*.mov,*.m2ts,*.mkv,*.vob,*.mpg,*.mpeg",
  ".mp3,*.oga,*.ogg,*.wav,*.flac",
  ".eot,*.otf,*.ttf,*.woff",
  ".doc,*.pdf,*.cbr,*.cbz",
  ".zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz,*.kgb",
  ".swp,.lock,.DS_Store,._*",
  ".,..",
})

------------------------------------------------------------
-- Security
------------------------------------------------------------
vim.opt.modelines = 0 -- Disable modelines for security reasons.
vim.opt.modeline = false -- Disable modeline for security reasons.
vim.opt.secure = true -- disallow autocmds in local dirs
