-- =========================================================
--  Leader keys
-- =========================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- =========================================================
--  UI
-- =========================================================
vim.opt.termguicolors = true
vim.opt.colorcolumn = "120"
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.pumblend = 10
vim.opt.pumheight = 10
vim.opt.signcolumn = "yes"
vim.opt.winborder = "rounded"
vim.opt.fillchars = { eob = " " }
vim.opt.linebreak = true
vim.opt.showtabline = 0

-- =========================================================
--  Window Behaviour
-- =========================================================
vim.opt.virtualedit = "block"
vim.opt.splitkeep = "screen"
vim.opt.splitright = true
vim.opt.splitbelow = true

-- =========================================================
--  Line numbers
-- =========================================================
vim.opt.number = true
vim.opt.relativenumber = true

-- =========================================================
--  Mouse
-- =========================================================
vim.opt.mouse = ""

-- =========================================================
--  Completions
-- =========================================================
vim.opt.inccommand = "split"
vim.opt.completeopt = "menu,menuone,fuzzy,noinsert"

-- =========================================================
--  Indentations
-- =========================================================
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.smartindent = true
vim.opt.breakindent = true

-- =========================================================
--  Searches
-- =========================================================
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.infercase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.path:append({ "**" })
vim.opt.grepprg = "rg --vimgrep --no-messages --smart-case"
vim.opt.wildoptions:append({ "fuzzy" })

-- =========================================================
--  Undos
-- =========================================================
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"

-- =========================================================
--  Spelling
-- =========================================================
vim.opt.iskeyword:append("-")

-- =========================================================
--  Wildmenu
-- =========================================================
vim.opt.wildmenu = true
vim.opt.wildignorecase = true
vim.opt.path:append("**")
vim.opt.wildignore:append({
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

-- =========================================================
--  Others
-- =========================================================
vim.opt.swapfile = false
vim.opt.confirm = true
vim.opt.updatetime = 50

-- =========================================================
--  Statusline
-- =========================================================

---Get current arglist status
---So that we can show it like [1/5]
---@return string
function _G.arglist_status()
  local args = vim.fn.argv()
  local total = #args

  if total == 0 then
    return ""
  end

  local current = vim.fn.expand("%:p")
  local index = -1

  for i, file in ipairs(args) do
    if vim.fn.fnamemodify(file, ":p") == current then
      index = i
      break
    end
  end

  if index == -1 then
    return string.format("[-/%d]", total)
  end

  return string.format("[%d/%d]", index, total)
end

vim.opt.statusline = table.concat({
  " %<%f",
  " %m%r",
  " %{v:lua.arglist_status()}",
  "%=",
  " %{&filetype}",
  " %l:%c",
  " %p%%",
})

-- =========================================================
--  Clipboard
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
