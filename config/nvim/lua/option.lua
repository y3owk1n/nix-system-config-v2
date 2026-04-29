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
vim.o.pumborder = "rounded"
vim.opt.signcolumn = "yes"
vim.opt.winborder = "rounded"
vim.opt.fillchars = { eob = " " }
vim.opt.linebreak = true
vim.opt.showtabline = 0
vim.o.cmdheight = 0

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

  if type(args) == "string" then
    args = vim.split(args, " ")
  end

  for i, file in ipairs(args) do
    if vim.fn.fnamemodify(file, ":p") == current then
      index = i
      break
    end
  end

  local text
  if index == -1 then
    text = string.format("[-/%d]", total)
  else
    text = string.format("[%d/%d]", index, total)
  end

  return " " .. text
end

function _G.lsp_clients()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if not clients or #clients == 0 then
    return ""
  end

  local names = {}
  local seen = {}

  for _, client in ipairs(clients) do
    if not seen[client.name] then
      seen[client.name] = true
      table.insert(names, client.name)
    end
  end

  return " [" .. table.concat(names, ",") .. "]"
end

function _G.diagnostic_status()
  local counts = vim.diagnostic.count(0)
  local icons = vim.diagnostic.config().signs.text
  local sev = vim.diagnostic.severity

  local order = { sev.ERROR, sev.WARN, sev.INFO, sev.HINT }
  local parts = {}

  for _, s in ipairs(order) do
    local count = counts[s]
    if count and count > 0 and icons and icons[s] then
      table.insert(parts, icons[s] .. count)
    end
  end

  if #parts == 0 then
    return ""
  end

  return " " .. table.concat(parts, " ")
end

function _G.mod_ro()
  local m = vim.bo.modified and "[+]" or ""
  local r = vim.bo.readonly and "[RO]" or ""

  if m == "" and r == "" then
    return ""
  end

  return " " .. m .. r
end

vim.opt.statusline = table.concat({
  " %<%f",
  "%{v:lua.mod_ro()}",
  "%{v:lua.arglist_status()}",
  "%=",
  "%{v:lua.diagnostic_status()}",
  "%{v:lua.lsp_clients()}",
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

-- =========================================================
--  Others
-- =========================================================

vim.opt.swapfile = false
vim.opt.confirm = true
vim.opt.updatetime = 50

-- this is only used to load .nvim.lua for tailwind overrides
vim.opt.exrc = true
