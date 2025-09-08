---@class Base16
local M = {}

local did_setup = false

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Base16.Config
---@field colors? table<Base16.Group.Raw, string> Colors to override
---@field disable_background? boolean Disable background color
---@field disable_float_background? boolean Disable floating window background color
---@field bold_vert_split? boolean Bold vertical splits
---@field dim_nc_background? boolean Dim non-current window background
---@field italic_comments? boolean Italicize comments
---@field italic_keywords? boolean Italicize keywords
---@field italic_booleans? boolean Italicize booleans
---@field italic_functions? boolean Italicize functions
---@field italic_variables? boolean Italicize variables
---@field transparent? boolean Transparent background
---@field highlight_groups? table<string, vim.api.keyset.highlight> Additional highlight groups to set
---@field before_highlight? fun(group: string, opts: table, c: table<Base16.Group.Alias, string>): nil Callback to run before setting highlight groups

---@alias Base16.Group.Raw "base00"|"base01"|"base02"|"base03"|"base04"|"base05"|"base06"|"base07"|"base08"|"base09"|"base0A"|"base0B"|"base0C"|"base0D"|"base0E"|"base0F"
---@alias Base16.Group.Alias "bg"|"bg_dim"|"bg_light"|"fg_dim"|"fg_dark"|"fg"|"fg_light"|"fg_bright"|"red"|"orange"|"yellow"|"green"|"cyan"|"blue"|"purple"|"brown"

---@param color string
local function color_to_rgb(color)
  local function byte(value, offset)
    return bit.band(bit.rshift(value, offset), 0xFF)
  end

  local new_color = vim.api.nvim_get_color_by_name(color)
  if new_color == -1 then
    new_color = vim.opt.background:get() == "dark" and 000 or 255255255
  end

  return { byte(new_color, 16), byte(new_color, 8), byte(new_color, 0) }
end

local blend_cache = {}

---@param fg string Foreground color
---@param bg string Background color
---@param alpha number Between 0 (background) and 1 (foreground)
local function blend(fg, bg, alpha)
  local cache_key = fg .. bg .. alpha
  if blend_cache[cache_key] then
    return blend_cache[cache_key]
  end

  local fg_rgb = color_to_rgb(fg)
  local bg_rgb = color_to_rgb(bg)

  local function blend_channel(i)
    local ret = (alpha * fg_rgb[i] + ((1 - alpha) * bg_rgb[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  local result = string.format("#%02X%02X%02X", blend_channel(1), blend_channel(2), blend_channel(3))

  blend_cache[cache_key] = result
  return result
end

---Reference `https://github.com/tinted-theming/home/blob/main/styling.md`
---@type table<Base16.Group.Alias, Base16.Group.Raw>
local base16_alias = {
  bg = "base00", -- Default background
  bg_dim = "base01", -- Lighter background (status line, etc.)
  bg_light = "base02", -- Selection background
  fg_dim = "base03", -- Comments, secondary text
  fg_dark = "base04", -- Dark foreground (default text)
  fg = "base05", -- Default foreground
  fg_light = "base06", -- Light foreground
  fg_bright = "base07", -- Brightest foreground
  red = "base08",
  orange = "base09",
  yellow = "base0A",
  green = "base0B",
  cyan = "base0C",
  blue = "base0D",
  purple = "base0E",
  brown = "base0F",
}

---@private
---Add semantic aliases to the raw colors
---@param raw_colors table<Base16.Group.Raw, string>
---@return table<Base16.Group.Alias, string>
local function add_semantic_palette(raw_colors)
  return setmetatable({}, {
    __index = function(_, k)
      -- 1. Exact match in the raw palette?
      local v = raw_colors[k]
      if v then
        return v
      end

      -- 2. Semantic alias?
      local canonical = base16_alias[k]
      if canonical then
        return raw_colors[canonical]
      end

      -- 3. Nothing found.
      return nil
    end,
  })
end

local function apply_highlights()
  local raw = M.config.colors or {}

  -- Validate that all required colors are provided
  local required_colors = {
    "base00",
    "base01",
    "base02",
    "base03",
    "base04",
    "base05",
    "base06",
    "base07",
    "base08",
    "base09",
    "base0A",
    "base0B",
    "base0C",
    "base0D",
    "base0E",
    "base0F",
  }

  for _, color in ipairs(required_colors) do
    if not raw[color] then
      error("Missing color: " .. color .. ". Please provide all base16 colors in setup()")
    end
  end

  local c = add_semantic_palette(raw)

  local highlights = {}

  -- Editor highlights
  highlights.Normal = { fg = c.fg, bg = M.config.transparent and c.bg or c.bg }
  highlights.NormalFloat = {
    fg = c.fg,
    bg = (M.config.disable_float_background or M.config.transparent) and c.bg or c.bg_dim,
  }
  highlights.NormalNC = {
    fg = c.fg,
    bg = M.config.dim_nc_background and c.bg_dim or (M.config.transparent and c.bg or c.bg),
  }

  highlights.FloatBorder = { fg = c.fg_dim }

  highlights.Cursor = { fg = c.bg, bg = c.fg }
  highlights.CursorLine = { bg = c.bg_light }
  highlights.CursorColumn = { bg = M.config.transparent and c.bg or c.bg_dim }
  highlights.CursorLineNr = { fg = c.fg_dark, bg = M.config.transparent and c.bg or c.bg_dim }
  highlights.LineNr = { fg = c.fg_dim }
  highlights.SignColumn = { fg = c.fg_dim, bg = M.config.transparent and c.bg or c.bg }
  highlights.ColorColumn = { bg = c.bg_dim }

  highlights.VertSplit = {
    fg = M.config.bold_vert_split and c.fg or c.bg_light,
    bold = M.config.bold_vert_split,
  }
  highlights.WinSeparator = { link = "VertSplit" }

  highlights.Folded = { fg = c.fg_dim, bg = c.bg_dim }
  highlights.FoldColumn = { fg = c.fg_dim }
  highlights.Conceal = { fg = c.fg_dim }

  highlights.Visual = { bg = c.bg_light }
  highlights.VisualNOS = { bg = c.bg_light }
  highlights.Search = { fg = c.bg_dim, bg = c.yellow }
  highlights.IncSearch = { fg = c.bg_dim, bg = c.orange }
  highlights.CurSearch = { link = "IncSearch" }
  highlights.Substitute = { link = "Search" }

  highlights.MatchParen = { bg = c.bg_light, bold = true }

  highlights.Pmenu = { fg = c.fg, bg = c.bg_dim }
  highlights.PmenuSel = { fg = c.bg_dim, bg = c.fg }
  highlights.PmenuSbar = { bg = c.bg_light }
  highlights.PmenuThumb = { bg = c.fg_dark }

  highlights.TabLine = { fg = c.fg_dim, bg = c.bg_dim }
  highlights.TabLineFill = { bg = c.bg_dim }
  highlights.TabLineSel = { fg = c.fg, bg = c.bg_light }

  highlights.StatusLine = { fg = c.fg_dark, bg = c.bg_light }
  highlights.StatusLineNC = { fg = c.fg_dim, bg = c.bg_dim }

  highlights.Directory = { fg = c.cyan }
  highlights.Title = { fg = c.cyan }

  -- Messages
  highlights.ErrorMsg = { fg = c.red }
  highlights.WarningMsg = { fg = c.orange }
  highlights.MoreMsg = { fg = c.green }
  highlights.ModeMsg = { fg = c.green }
  highlights.Question = { fg = c.blue }

  -- Diff
  highlights.DiffAdd = { fg = c.green, bg = c.bg_dim }
  highlights.DiffChange = { fg = c.orange, bg = c.bg_dim }
  highlights.DiffDelete = { fg = c.red, bg = c.bg_dim }
  highlights.DiffText = { fg = c.blue, bg = c.bg_dim }

  -- Spelling
  highlights.SpellBad = { sp = c.red, undercurl = true }
  highlights.SpellCap = { sp = c.blue, undercurl = true }
  highlights.SpellLocal = { sp = c.cyan, undercurl = true }
  highlights.SpellRare = { sp = c.purple, undercurl = true }

  -- Syntax highlighting
  highlights.Comment = {
    fg = c.fg_dim,
    italic = M.config.italic_comments,
  }

  highlights.Constant = { fg = c.orange }
  highlights.String = { fg = c.yellow }
  highlights.Character = { fg = c.orange }
  highlights.Number = { fg = c.orange }
  highlights.Boolean = {
    fg = c.orange,
    italic = M.config.italic_booleans,
  }
  highlights.Float = { fg = c.orange }

  highlights.Identifier = {
    fg = c.fg,
    italic = M.config.italic_variables,
  }
  highlights.Function = {
    fg = c.orange,
    italic = M.config.italic_functions,
  }

  highlights.Statement = { fg = c.purple }
  highlights.Conditional = { fg = c.purple }
  highlights.Repeat = { fg = c.purple }
  highlights.Label = { fg = c.cyan }
  highlights.Operator = { fg = c.fg }
  highlights.Keyword = {
    fg = c.purple,
    italic = M.config.italic_keywords,
  }
  highlights.Exception = { fg = c.red }

  highlights.PreProc = { fg = c.yellow }
  highlights.Include = { fg = c.blue }
  highlights.Define = { fg = c.purple }
  highlights.Macro = { fg = c.red }
  highlights.PreCondit = { fg = c.yellow }

  highlights.Type = { fg = c.yellow }
  highlights.StorageClass = { fg = c.yellow }
  highlights.Structure = { fg = c.purple }
  highlights.Typedef = { fg = c.yellow }

  highlights.Special = { fg = c.cyan }
  highlights.SpecialChar = { fg = c.brown }
  highlights.Tag = { fg = c.cyan }
  highlights.Delimiter = { fg = c.brown }
  highlights.SpecialComment = { fg = c.cyan }
  highlights.Debug = { fg = c.red }

  highlights.Underlined = { fg = c.blue, underline = true }
  highlights.Ignore = { fg = c.fg_dim }
  highlights.Error = { fg = c.red, bg = c.bg }
  highlights.Todo = { fg = c.yellow, bg = c.bg_dim }

  -- Treesitter highlights
  highlights["@variable"] = {
    fg = c.fg,
    italic = M.config.italic_variables,
  }
  highlights["@variable.builtin"] = { fg = c.orange }
  highlights["@variable.parameter"] = { fg = c.purple }
  highlights["@variable.parameter.builtin"] = { fg = c.purple }
  highlights["@variable.member"] = { fg = c.cyan }

  highlights["@constant"] = { fg = c.orange }
  highlights["@constant.builtin"] = { fg = c.orange }
  highlights["@constant.macro"] = { fg = c.orange }

  highlights["@module"] = { fg = c.fg }
  highlights["@module.builtin"] = { fg = c.fg }
  highlights["@label"] = { link = "Label" }

  highlights["@string"] = { link = "String" }
  highlights["@string.regexp"] = { fg = c.cyan }
  highlights["@string.escape"] = { fg = c.cyan }
  highlights["@string.special"] = { fg = c.cyan }

  highlights["@character"] = { link = "Character" }
  highlights["@character.special"] = { fg = c.cyan }

  highlights["@boolean"] = {
    fg = c.orange,
    italic = M.config.italic_booleans,
  }
  highlights["@number"] = { fg = c.orange }
  highlights["@number.float"] = { fg = c.orange }

  highlights["@type"] = { fg = c.cyan }
  highlights["@type.builtin"] = { fg = c.cyan }

  highlights["@attribute"] = { fg = c.yellow }
  highlights["@property"] = { fg = c.cyan }

  highlights["@function"] = {
    fg = c.blue,
    italic = M.config.italic_functions,
  }
  highlights["@function.builtin"] = { fg = c.blue }
  highlights["@function.call"] = { fg = c.blue }
  highlights["@function.macro"] = { link = "Function" }

  highlights["@function.method"] = { fg = c.blue }
  highlights["@function.method.call"] = { fg = c.blue }

  highlights["@constructor"] = { fg = c.fg_dim }
  highlights["@operator"] = { fg = c.fg }

  highlights["@keyword"] = {
    link = "Keyword",
    italic = M.config.italic_keywords,
  }
  highlights["@keyword.function"] = { link = "Function" }
  highlights["@keyword.operator"] = { fg = c.fg }
  highlights["@keyword.import"] = { fg = c.blue }
  highlights["@keyword.storage"] = { fg = c.cyan }
  highlights["@keyword.repeat"] = { fg = c.blue }
  highlights["@keyword.return"] = { fg = c.blue }
  highlights["@keyword.debug"] = { fg = c.red }
  highlights["@keyword.conditional"] = { fg = c.blue }
  highlights["@keyword.exception"] = { fg = c.red }
  highlights["@keyword.directive"] = { fg = c.purple }

  highlights["@punctuation.delimiter"] = { fg = c.brown }
  highlights["@punctuation.bracket"] = { fg = c.brown }
  highlights["@punctuation.special"] = { fg = c.brown }

  highlights["@comment"] = {
    fg = c.fg_dim,
    italic = M.config.italic_comments,
  }
  highlights["@comment.documentation"] = { fg = c.fg_dark }

  highlights["@markup.strong"] = { bold = true }
  highlights["@markup.italic"] = { italic = true }
  highlights["@markup.strikethrough"] = { strikethrough = true }
  highlights["@markup.underline"] = { underline = true }

  highlights["@markup.heading"] = { fg = c.blue, bold = true }
  highlights["@markup.quote"] = { fg = c.fg_dim }
  highlights["@markup.list"] = { fg = c.red }
  highlights["@markup.link"] = { fg = c.blue, underline = true }
  highlights["@markup.raw"] = { fg = c.green }

  highlights["@diff.plus"] = { fg = c.green }
  highlights["@diff.minus"] = { fg = c.red }
  highlights["@diff.delta"] = { fg = c.purple }

  highlights["@tag"] = { link = "Tag" }
  highlights["@tag.attribute"] = { fg = c.purple }
  highlights["@tag.delimiter"] = { fg = c.brown }

  -- Diagnostic highlights
  highlights.DiagnosticError = { fg = c.red }
  highlights.DiagnosticWarn = { fg = c.orange }
  highlights.DiagnosticInfo = { fg = c.blue }
  highlights.DiagnosticHint = { fg = c.cyan }

  highlights.DiagnosticUnderlineError = { sp = c.red, undercurl = true }
  highlights.DiagnosticUnderlineWarn = { sp = c.orange, undercurl = true }
  highlights.DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true }
  highlights.DiagnosticUnderlineHint = { sp = c.cyan, undercurl = true }

  -- LSP highlights
  highlights.LspReferenceText = { bg = c.bg_light }
  highlights.LspReferenceRead = { bg = c.bg_light }
  highlights.LspReferenceWrite = { bg = c.bg_light }

  -- Plugin highlights

  --Mini Icons
  highlights.MiniIconsAzure = { fg = c.cyan }
  highlights.MiniIconsBlue = { fg = c.blue }
  highlights.MiniIconsCyan = { fg = c.cyan }
  highlights.MiniIconsGreen = { fg = c.green }
  highlights.MiniIconsGrey = { fg = c.fg_dim }
  highlights.MiniIconsOrange = { fg = c.orange }
  highlights.MiniIconsPurple = { fg = c.purple }
  highlights.MiniIconsRed = { fg = c.red }
  highlights.MiniIconsYellow = { fg = c.yellow }

  -- Apply custom highlights from user M.configuration
  if M.config.highlight_groups and next(M.config.highlight_groups) then
    for group, highlight in pairs(M.config.highlight_groups) do
      local existing = highlights[group] or {}

      -- Handle link references
      while existing.link do
        existing = highlights[existing.link] or {}
      end

      -- Parse colors if they reference base16 colors
      local parsed = {}
      for key, value in pairs(highlight) do
        if key == "fg" or key == "bg" or key == "sp" then
          -- Allow referencing base16 colors like "red"
          if type(value) == "string" and value:match("^base[0-9A-F][0-9A-F]$") then
            parsed[key] = c[value] -- red, cyan, …
          elseif type(value) == "string" and c[value] then
            parsed[key] = c[value] -- red, cyan, bg, fg, …
          else
            parsed[key] = value -- plain "#rrggbb" or whatever
          end
        else
          parsed[key] = value
        end
      end

      highlights[group] = parsed
    end
  end

  -- Apply all highlights
  for group, opts in pairs(highlights) do
    -- Call before_highlight hook if provided
    if M.config.before_highlight then
      M.config.before_highlight(group, opts, c)
    end

    if opts.blend ~= nil and (opts.blend >= 0 and opts.blend <= 100) and opts.bg ~= nil then
      local bg_hex = c[opts.bg] or opts.bg
      opts.bg = blend(bg_hex, opts.blend_on or c.bg, opts.blend / 100)
    end

    opts.blend = nil
    opts.blend_on = nil

    if opts._nvim_blend ~= nil then
      opts.blend = opts._nvim_blend
    end

    vim.api.nvim_set_hl(0, group, opts)
  end
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@type Base16.Config
M.config = {}

---@type Base16.Config
local default_config = {
  colors = {},
  highlight_groups = {},
  before_highlight = nil,
  disable_background = false,
  disable_float_background = false,
  bold_vert_split = false,
  dim_nc_background = false,
  italic_comments = false,
  italic_keywords = false,
  italic_booleans = false,
  italic_functions = false,
  italic_variables = false,
  transparent = false,
}

---Setup the base16 plugin
---@param user_config? Base16.Config
function M.setup(user_config)
  if did_setup then
    vim.notify("Base16: Plugin already set up", vim.log.levels.WARN)
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

  -- Validate colors
  if not M.config.colors or type(M.config.colors) ~= "table" then
    error("colors table is required in setup(). Please provide colors.")
  end

  did_setup = true
end

function M.colorscheme()
  -- Clear existing highlights
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  -- Enable termguicolors
  vim.opt.termguicolors = true

  -- Apply highlights
  apply_highlights()
end

-- Auto command to load colorscheme
function M.load()
  M.colorscheme()
end

return M
