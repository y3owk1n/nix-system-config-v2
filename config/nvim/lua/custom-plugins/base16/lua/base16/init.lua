---@class Base16
local M = {}

local did_setup = false

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Base16.Config
---@field colors? table<Base16.Group.Raw, string> Colors to override
---@field bold_vert_split? boolean Bold vertical splits
---@field enable_bold? boolean Enable bold text
---@field enable_italics? boolean Enable italics
---@field enable_transparency? boolean Transparent background
---@field dim_inactive_windows? boolean Dim inactive windows
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

-- Standardized blend values
local BLEND = {
  subtle = 10, -- barely visible backgrounds
  medium = 15, -- noticeable but not distracting
  strong = 25, -- prominent highlights
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

-- Helper function for consistent transparency handling
local function get_bg(normal_bg, transparent_override)
  if M.config.enable_transparency then
    return transparent_override or "NONE"
  end
  return normal_bg
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_editor_hl(highlights, c)
  -- Normal/Float/NC
  highlights.Normal = { fg = c.fg, bg = get_bg(c.bg) }
  highlights.NormalFloat = { fg = c.fg, bg = get_bg(c.bg) }
  highlights.NormalNC = {
    fg = c.fg,
    bg = (M.config.dim_inactive_windows and c.bg_dim) or get_bg(c.bg),
    blend = M.config.dim_inactive_windows and 50,
  }

  -- Cursor & Lines
  highlights.Cursor = { fg = c.bg, bg = c.fg }
  highlights.CursorLine = { bg = c.bg_light }
  highlights.CursorColumn = { bg = get_bg(c.bg_dim) }
  highlights.CursorLineNr = {
    fg = c.fg_dark,
    bg = get_bg(c.bg_dim),
    bold = M.config.enable_bold,
  }
  highlights.LineNr = { fg = c.fg_dim, bg = get_bg(c.bg) }
  highlights.SignColumn = { fg = c.fg_dim, bg = get_bg(c.bg) }
  highlights.ColorColumn = { bg = get_bg(c.bg_dim) }

  -- Split & Windows
  highlights.VertSplit = {
    fg = M.config.bold_vert_split and c.fg or c.fg_dim,
    bold = M.config.bold_vert_split,
  }
  highlights.WinSeparator = { fg = c.fg_dim }
  highlights.WinBar = { fg = c.fg_dark, bg = get_bg(c.bg_light) }
  highlights.WinBarNC = { fg = c.fg_dim, bg = get_bg(c.bg_dim) }

  -- Fold & Conceals
  highlights.Folded = { fg = c.fg_dim, bg = get_bg(c.bg_dim) }
  highlights.FoldColumn = { fg = c.fg_dim, bg = get_bg(c.bg) }
  highlights.Conceal = { fg = c.fg_dim }

  -- Visual & Selection - Fixed bold consistency
  highlights.Visual = { bg = c.bg_light }
  highlights.VisualNOS = { bg = c.bg_light }
  highlights.MatchParen = { bg = c.bg_light, bold = M.config.enable_bold }

  -- Search
  highlights.Search = { fg = c.bg, bg = c.yellow }
  highlights.IncSearch = { link = "CurSearch" }
  highlights.CurSearch = { fg = c.bg, bg = c.orange }
  highlights.Substitute = { link = "IncSearch" }

  -- Popup Menu
  highlights.Pmenu = { fg = c.fg, bg = get_bg(c.bg_dim) }
  highlights.PmenuSel = { bg = c.bg_light, bold = M.config.enable_bold }
  highlights.PmenuSbar = { bg = c.bg_light }
  highlights.PmenuThumb = { bg = c.fg_dark }

  -- Tabline
  highlights.TabLine = { fg = c.fg_dim, bg = get_bg(c.bg_dim) }
  highlights.TabLineFill = { bg = get_bg(c.bg_dim) }
  highlights.TabLineSel = { fg = c.fg, bg = c.bg_light, bold = M.config.enable_bold }

  -- Statusline
  highlights.StatusLine = { fg = c.fg_dark, bg = c.bg_dim }
  highlights.StatusLineNC = { fg = c.fg_dim, bg = c.bg_dim }

  -- Misc UI
  highlights.FloatBorder = { fg = c.fg_dim }
  highlights.FloatShadow = { bg = c.bg_light }
  highlights.FloatShadowThrough = { link = "FloatShadow" }
  highlights.WildMenu = { link = "IncSearch" }
  highlights.Directory = { fg = c.cyan, bold = M.config.enable_bold }
  highlights.Title = { fg = c.cyan, bold = M.config.enable_bold }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_message_hl(highlights, c)
  highlights.ErrorMsg = { fg = c.red, bold = M.config.enable_bold }
  highlights.WarningMsg = { fg = c.orange, bold = M.config.enable_bold }
  highlights.MoreMsg = { fg = c.green }
  highlights.ModeMsg = { fg = c.green }
  highlights.Question = { fg = c.blue }
  highlights.NvimInternalError = { link = "ErrorMsg" }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_diff_hl(highlights, c)
  highlights.DiffAdd = { fg = c.green }
  highlights.DiffChange = { fg = c.orange }
  highlights.DiffDelete = { fg = c.red }
  highlights.DiffText = { fg = c.blue }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_spelling_hl(highlights, c)
  highlights.SpellBad = { sp = c.red, undercurl = true }
  highlights.SpellCap = { sp = c.blue, undercurl = true }
  highlights.SpellLocal = { sp = c.cyan, undercurl = true }
  highlights.SpellRare = { sp = c.purple, undercurl = true }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_syntax_hl(highlights, c)
  -- Comments
  highlights.Comment = {
    fg = c.fg_dim,
    italic = M.config.enable_italics,
  }
  -- Constants
  highlights.Constant = { fg = c.orange }
  highlights.String = { fg = c.yellow }
  highlights.Character = { fg = c.orange }
  highlights.Number = { fg = c.orange }
  highlights.Boolean = {
    fg = c.orange,
    italic = M.config.enable_italics,
  }
  highlights.Float = { fg = c.orange }
  highlights.FloatTitle = { fg = c.cyan, bg = get_bg(c.bg), bold = M.config.enable_bold }

  -- Identifiers
  highlights.Identifier = {
    fg = c.fg,
    italic = M.config.enable_italics,
  }
  highlights.Function = {
    fg = c.orange,
    italic = M.config.enable_italics,
  }

  -- Statement & Keywords
  highlights.Statement = { fg = c.blue, bold = M.config.enable_bold }
  highlights.Conditional = { fg = c.purple }
  highlights.Repeat = { fg = c.purple }
  highlights.Label = { fg = c.cyan }
  highlights.Operator = { fg = c.fg }
  highlights.Keyword = {
    fg = c.purple,
    italic = M.config.enable_italics,
  }
  highlights.Exception = { fg = c.red }

  -- Preprocessor
  highlights.PreProc = { link = "PreCondit" }
  highlights.Include = { fg = c.blue }
  highlights.Define = { fg = c.purple }
  highlights.Macro = { fg = c.red }
  highlights.PreCondit = { fg = c.purple }

  -- Types
  highlights.Type = { fg = c.cyan }
  highlights.StorageClass = { fg = c.yellow }
  highlights.Structure = { fg = c.cyan }
  highlights.Typedef = { link = "Type" }

  -- Specials
  highlights.Special = { fg = c.cyan }
  highlights.SpecialChar = { link = "Special" }
  highlights.Tag = { fg = c.cyan }
  highlights.Delimiter = { fg = c.brown }
  highlights.SpecialComment = { link = "Special" }
  highlights.Debug = { fg = c.red }

  -- Markdown
  highlights.markdownH1 = { fg = c.red, bold = M.config.enable_bold }
  highlights.markdownH1Delimiter = { link = "markdownH1" }
  highlights.markdownH2 = { fg = c.orange, bold = M.config.enable_bold }
  highlights.markdownH2Delimiter = { link = "markdownH2" }
  highlights.markdownH3 = { fg = c.yellow, bold = M.config.enable_bold }
  highlights.markdownH3Delimiter = { link = "markdownH3" }
  highlights.markdownH4 = { fg = c.green, bold = M.config.enable_bold }
  highlights.markdownH4Delimiter = { link = "markdownH4" }
  highlights.markdownH5 = { fg = c.cyan, bold = M.config.enable_bold }
  highlights.markdownH5Delimiter = { link = "markdownH5" }
  highlights.markdownH6 = { fg = c.blue, bold = M.config.enable_bold }
  highlights.markdownH6Delimiter = { link = "markdownH6" }
  highlights.markdownLinkText = { link = "markdownUrl" }
  highlights.markdownUrl = { fg = c.purple, sp = c.purple, underline = true }

  -- Misc
  highlights.Underlined = { underline = true }
  highlights.Bold = { bold = M.config.enable_bold }
  highlights.Italic = { italic = M.config.enable_italics }
  highlights.Ignore = { fg = c.fg_dim }
  highlights.Error = { fg = c.red, bg = get_bg(c.bg) }
  highlights.Todo = { fg = c.yellow, bg = get_bg(c.bg_dim) }
  highlights.healthError = { fg = c.red }
  highlights.healthSuccess = { fg = c.green }
  highlights.healthWarning = { fg = c.orange }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_treesitter_hl(highlights, c)
  highlights["@variable"] = {
    fg = c.fg,
    italic = M.config.enable_italics,
  }
  highlights["@variable.builtin"] = { fg = c.orange, bold = M.config.enable_bold }
  highlights["@variable.parameter"] = { fg = c.purple }
  highlights["@variable.parameter.builtin"] = { fg = c.purple, bold = M.config.enable_bold }
  highlights["@variable.member"] = { fg = c.cyan }

  highlights["@constant"] = { link = "Constant" }
  highlights["@constant.builtin"] = { fg = c.orange, bold = M.config.enable_bold }
  highlights["@constant.macro"] = { fg = c.orange }

  highlights["@module"] = { fg = c.fg }
  highlights["@module.builtin"] = { fg = c.fg, bold = M.config.enable_bold }
  highlights["@label"] = { link = "Label" }

  highlights["@string"] = { link = "String" }
  highlights["@string.regexp"] = { fg = c.purple }
  highlights["@string.escape"] = { fg = c.blue }
  highlights["@string.special"] = { link = "String" }
  highlights["@string.special.symbol"] = { link = "Identifier" }
  highlights["@string.special.url"] = { fg = c.purple }

  highlights["@punctuation.delimiter.regex"] = { link = "@string.regexp" }

  highlights["@character"] = { link = "Character" }
  highlights["@character.special"] = { link = "Character" }

  highlights["@boolean"] = { link = "Boolean" }
  highlights["@number"] = { link = "Number" }
  highlights["@number.float"] = { link = "Number" }
  highlights["@float"] = { link = "Number" }

  highlights["@type"] = { fg = c.orange }
  highlights["@type.builtin"] = { fg = c.orange, bold = M.config.enable_bold }
  highlights["@type.definition"] = { link = "Type" }

  highlights["@attribute"] = { fg = c.yellow }
  highlights["@attribute.builtin"] = { fg = c.yellow, bold = M.config.enable_bold }

  highlights["@property"] = { fg = c.cyan }

  highlights["@function"] = { link = "Function" }
  highlights["@function.builtin"] = { fg = c.blue, bold = M.config.enable_bold }

  highlights["@function.call"] = { link = "Function" }
  highlights["@function.macro"] = { link = "Function" }
  highlights["@function.method"] = { link = "Function" }
  highlights["@function.method.call"] = { link = "Function" }

  highlights["@constructor"] = { fg = c.fg_dim }
  highlights["@operator"] = { link = "Operator" }

  highlights["@keyword"] = { link = "Keyword" }
  highlights["@keyword.modifier"] = { link = "Function" }
  highlights["@keyword.type"] = { link = "Function" }
  highlights["@keyword.coroutine"] = { link = "Function" }
  highlights["@keyword.function"] = { fg = c.blue }
  highlights["@keyword.operator"] = { fg = c.blue }
  highlights["@keyword.import"] = { link = "Include" }
  highlights["@keyword.repeat"] = { link = "Repeat" }
  highlights["@keyword.return"] = { fg = c.blue }
  highlights["@keyword.debug"] = { link = "Exception" }
  highlights["@keyword.exception"] = { link = "Exception" }
  highlights["@keyword.conditional"] = { link = "Conditional" }
  highlights["@keyword.conditional.ternary"] = { link = "Operator" }
  highlights["@keyword.directive"] = { link = "PreProc" }
  highlights["@keyword.directive.define"] = { link = "Define" }
  highlights["@keyword.export"] = { fg = c.blue, italic = M.config.enable_italics }

  highlights["@punctuation.delimiter"] = { link = "Delimiter" }
  highlights["@punctuation.bracket"] = { fg = c.brown }
  highlights["@punctuation.special"] = { link = "Special" }

  highlights["@comment"] = { link = "Comment" }
  highlights["@comment.documentation"] = { link = "Comment" }

  highlights["@markup.heading.1.markdown"] = { link = "markdownH1" }
  highlights["@markup.heading.2.markdown"] = { link = "markdownH2" }
  highlights["@markup.heading.3.markdown"] = { link = "markdownH3" }
  highlights["@markup.heading.4.markdown"] = { link = "markdownH4" }
  highlights["@markup.heading.5.markdown"] = { link = "markdownH5" }
  highlights["@markup.heading.6.markdown"] = { link = "markdownH6" }
  highlights["@markup.heading.1.marker.markdown"] = { link = "markdownH1Delimiter" }
  highlights["@markup.heading.2.marker.markdown"] = { link = "markdownH2Delimiter" }
  highlights["@markup.heading.3.marker.markdown"] = { link = "markdownH3Delimiter" }
  highlights["@markup.heading.4.marker.markdown"] = { link = "markdownH4Delimiter" }
  highlights["@markup.heading.5.marker.markdown"] = { link = "markdownH5Delimiter" }
  highlights["@markup.heading.6.marker.markdown"] = { link = "markdownH6Delimiter" }

  highlights["@markup.strong"] = { bold = M.config.enable_bold }
  highlights["@markup.italic"] = { italic = M.config.enable_italics }
  highlights["@markup.strikethrough"] = { strikethrough = true }
  highlights["@markup.underline"] = { underline = true }

  highlights["@markup.heading"] = { fg = c.cyan, bold = M.config.enable_bold }
  highlights["@markup.quote"] = { fg = c.fg_dim }
  highlights["@markup.list"] = { fg = c.red }
  highlights["@markup.link"] = { fg = c.purple, underline = true }
  highlights["@markup.raw"] = { fg = c.green }

  highlights["@diff.plus"] = { fg = c.green }
  highlights["@diff.minus"] = { fg = c.red }
  highlights["@diff.delta"] = { fg = c.purple }

  highlights["@tag"] = { link = "Tag" }
  highlights["@tag.attribute"] = { fg = c.purple }
  highlights["@tag.delimiter"] = { fg = c.brown }

  --- Semantic
  highlights["@lsp.type.comment"] = {}
  highlights["@lsp.type.comment.c"] = { link = "@comment" }
  highlights["@lsp.type.comment.cpp"] = { link = "@comment" }
  highlights["@lsp.type.enum"] = { link = "@type" }
  highlights["@lsp.type.interface"] = { link = "@interface" }
  highlights["@lsp.type.keyword"] = { link = "@keyword" }
  highlights["@lsp.type.namespace"] = { link = "@namespace" }
  highlights["@lsp.type.namespace.python"] = { link = "@variable" }
  highlights["@lsp.type.parameter"] = { link = "@parameter" }
  highlights["@lsp.type.property"] = { link = "@property" }
  highlights["@lsp.type.variable"] = {} -- defer to treesitter for regular variables
  highlights["@lsp.type.variable.svelte"] = { link = "@variable" }
  highlights["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" }
  highlights["@lsp.typemod.operator.injected"] = { link = "@operator" }
  highlights["@lsp.typemod.string.injected"] = { link = "@string" }
  highlights["@lsp.typemod.variable.constant"] = { link = "@constant" }
  highlights["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" }
  highlights["@lsp.typemod.variable.injected"] = { link = "@variable" }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_diagnostics_hl(highlights, c)
  highlights.DiagnosticError = { fg = c.red }
  highlights.DiagnosticWarn = { fg = c.orange }
  highlights.DiagnosticInfo = { fg = c.blue }
  highlights.DiagnosticHint = { fg = c.purple }
  highlights.DiagnosticUnderlineError = { sp = c.red, undercurl = true }
  highlights.DiagnosticUnderlineWarn = { sp = c.orange, undercurl = true }
  highlights.DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true }
  highlights.DiagnosticUnderlineHint = { sp = c.purple, undercurl = true }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_lsp_hl(highlights, c)
  highlights.LspReferenceText = { bg = c.bg_light }
  highlights.LspReferenceRead = { bg = c.bg_light }
  highlights.LspReferenceWrite = { bg = c.bg_light }
end

---@param highlights table<string, table> The highlights table to setup
---@param c table<Base16.Group.Alias, string> The semantic color palette
local function setup_integration_hl(highlights, c)
  -- Mini Icons
  highlights.MiniIconsAzure = { fg = c.cyan }
  highlights.MiniIconsBlue = { fg = c.blue }
  highlights.MiniIconsCyan = { fg = c.cyan }
  highlights.MiniIconsGreen = { fg = c.green }
  highlights.MiniIconsGrey = { fg = c.fg_dim }
  highlights.MiniIconsOrange = { fg = c.orange }
  highlights.MiniIconsPurple = { fg = c.purple }
  highlights.MiniIconsRed = { fg = c.red }
  highlights.MiniIconsYellow = { fg = c.yellow }

  -- Mini Diff
  highlights.MiniDiffAdd = { link = "DiffAdd" }
  highlights.MiniDiffChange = { link = "DiffChange" }
  highlights.MiniDiffDelete = { link = "DiffDelete" }
  highlights.MiniDiffSignAdd = { link = "DiffAdd" }
  highlights.MiniDiffSignChange = { link = "DiffChange" }
  highlights.MiniDiffSignDelete = { link = "DiffDelete" }

  -- Render Markdown
  highlights.RenderMarkdownH1Bg = { bg = c.red, blend = BLEND.medium }
  highlights.RenderMarkdownH2Bg = { bg = c.orange, blend = BLEND.medium }
  highlights.RenderMarkdownH3Bg = { bg = c.yellow, blend = BLEND.medium }
  highlights.RenderMarkdownH4Bg = { bg = c.green, blend = BLEND.medium }
  highlights.RenderMarkdownH5Bg = { bg = c.cyan, blend = BLEND.medium }
  highlights.RenderMarkdownH6Bg = { bg = c.blue, blend = BLEND.medium }
  highlights.RenderMarkdownBullet = { fg = c.orange }
  highlights.RenderMarkdownChecked = { fg = c.cyan }
  highlights.RenderMarkdownUnchecked = { fg = c.fg_dim }
  highlights.RenderMarkdownCode = { bg = c.bg_dim }
  highlights.RenderMarkdownCodeInline = { bg = c.bg_dim, fg = c.fg }
  highlights.RenderMarkdownQuote = { fg = c.fg_dim }
  highlights.RenderMarkdownTableFill = { link = "Conceal" }
  highlights.RenderMarkdownTableHead = { fg = c.fg_dim }
  highlights.RenderMarkdownTableRow = { fg = c.fg_dim }

  -- Undoglow
  highlights.UgUndo = { bg = c.red, blend = BLEND.strong }
  highlights.UgRedo = { bg = c.green, blend = BLEND.strong }
  highlights.UgYank = { bg = c.orange, blend = BLEND.strong }
  highlights.UgPaste = { bg = c.cyan, blend = BLEND.strong }
  highlights.UgSearch = { bg = c.blue, blend = BLEND.strong }
  highlights.UgComment = { bg = c.yellow, blend = BLEND.strong }
  highlights.UgCursor = { bg = c.bg_light }

  -- Blink Cmp
  highlights.BlinkCmpMenuBorder = { link = "FloatBorder" }
  highlights.BlinkCmpDocBorder = { link = "FloatBorder" }

  -- Grugfar
  highlights.GrugFarResultsMatch = { link = "IncSearch" }
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

  setup_editor_hl(highlights, c)
  setup_message_hl(highlights, c)
  setup_diff_hl(highlights, c)
  setup_spelling_hl(highlights, c)
  setup_syntax_hl(highlights, c)
  setup_treesitter_hl(highlights, c)
  setup_diagnostics_hl(highlights, c)
  setup_lsp_hl(highlights, c)
  setup_integration_hl(highlights, c)

  -- Apply custom highlights from user configuration
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
  bold_vert_split = false,
  enable_bold = false,
  enable_italics = false,
  enable_transparency = false,
  dim_inactive_windows = false,
}

-- Cache for the semantic palette
local _cached_colors = nil

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

---Get the semantic color palette
---@return table<Base16.Group.Alias, string>|nil colors The semantic color palette, or nil if not set up
function M.colors()
  if not did_setup then
    vim.notify("Base16: Plugin not set up. Call setup() first.", vim.log.levels.ERROR)
    return nil
  end

  if not M.config.colors then
    vim.notify("Base16: No colors configured.", vim.log.levels.ERROR)
    return nil
  end

  -- Return cached colors if available
  if _cached_colors then
    return _cached_colors
  end

  -- Create and cache the semantic palette
  _cached_colors = add_semantic_palette(M.config.colors)
  return _cached_colors
end

---Get a specific color by name
---@param name Base16.Group.Alias|Base16.Group.Raw Color name (e.g., "red", "bg", "base08")
---@return string|nil color The hex color value, or nil if not found
function M.get_color(name)
  local colors = M.colors()
  if not colors then
    return nil
  end
  return colors[name]
end

---Get multiple colors at once
---@param names Base16.Group.Alias[]|Base16.Group.Raw[] Array of color names
---@return table<string, string> colors Map of color names to hex values
function M.get_colors(names)
  local colors = M.colors()
  local result = {}

  if not colors then
    return result
  end

  for _, name in ipairs(names) do
    local color = colors[name]
    if color then
      result[name] = color
    end
  end

  return result
end

---Get all raw base16 colors
---@return table<Base16.Group.Raw, string>|nil colors The raw base16 colors, or nil if not set up
function M.raw_colors()
  if not did_setup or not M.config.colors then
    return nil
  end

  -- Return a copy to prevent modification
  local raw = {}
  for k, v in pairs(M.config.colors) do
    raw[k] = v
  end
  return raw
end

---Get semantic color mapping
---@return table<Base16.Group.Alias, Base16.Group.Raw> mapping The semantic to raw color mapping
function M.color_mapping()
  return vim.deepcopy(base16_alias)
end

---Blend two colors together
---@param fg_color string Foreground color (hex)
---@param bg_color string Background color (hex)
---@param alpha number Alpha value between 0 (background) and 1 (foreground)
---@return string blended_color The blended color as hex
function M.blend_colors(fg_color, bg_color, alpha)
  return blend(fg_color, bg_color, alpha)
end

---Get standardized blend values
---@return table<string, number> blend_values The standardized blend values
function M.blend_values()
  return vim.deepcopy(BLEND)
end

---Invalidate the color cache (useful when colors are updated)
---@private
function M._invalidate_cache()
  _cached_colors = nil
end

return M
