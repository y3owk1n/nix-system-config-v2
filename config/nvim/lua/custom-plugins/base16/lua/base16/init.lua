---@mod base16.nvim Base16 colorscheme plugin
---@brief [[
---Base16 is a highly configurable colorscheme engine for Neovim that
---aims to not only covers base16 colorschemes, but also include features
---that are built-in to most colorscheme plugins (e.g. dim_inactive_windows,
---blends, italics, custom highlights, etc.)
---
---It allows defining a semantic color palette, generating highlight
---groups automatically, and integrating with popular plugins.
--
---Features: ~
---  • Semantic color aliases (bg, fg, red, etc.)
---  • Configurable style options (bold, italic, blends, transparency)
---  • Automatic Neovim UI, syntax, Treesitter, and LSP highlights
---  • Plugin integrations (Mini, Blink, RenderMarkdown, etc.)
--
---Usage: ~
--->lua
---  require("base16").setup({
---    colors = {
---      base00 = "#1f1f28", base01 = "#2a2a37", base02 = "#3a3a4e",
---      base03 = "#4e4e5e", base04 = "#9e9eaf", base05 = "#c5c5da",
---      base06 = "#dfdfef", base07 = "#e6e6f0", base08 = "#ff5f87",
---      base09 = "#ff8700", base0A = "#ffaf00", base0B = "#5fff87",
---      base0C = "#5fd7ff", base0D = "#5fafff", base0E = "#af87ff",
---      base0F = "#d7875f",
---    },
---  })
---  vim.cmd.colorscheme("base16")
---<
---@brief ]]

---@toc base16.contents

---@class Base16
local M = {}

local did_setup = false

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class Base16.Config
---@field colors? table<Base16.Group.Raw, string> Colors to override
---@field styles? Base16.Config.Styles Styles to override
---@field highlight_groups? table<string, vim.api.keyset.highlight> Additional highlight groups to set
---@field before_highlight? fun(group: string, opts: vim.api.keyset.highlight, c: table<Base16.Group.Alias, string>): nil Callback to run before setting highlight groups
---@field plugins? Base16.Config.Plugins Enable/disable plugins
---@field color_groups? Base16.Config.ColorGroups Color groups to override

---@class Base16.Config.ColorGroups
---@field backgrounds? Base16.Config.ColorGroups.Backgrounds Background colors
---@field foregrounds? Base16.Config.ColorGroups.Foregrounds Foreground colors
---@field syntax? Base16.Config.ColorGroups.Syntax Syntax colors
---@field states? Base16.Config.ColorGroups.States Semantic colors
---@field diff? Base16.Config.ColorGroups.Diff Diff colors
---@field search? Base16.Config.ColorGroups.Search Search colors

---@alias Base16.Config.ColorGroups.Color string|fun(c: table<Base16.Group.Alias, string>): string

---@class Base16.Config.ColorGroups.Backgrounds
---@field normal? Base16.Config.ColorGroups.Color Normal background
---@field dim? Base16.Config.ColorGroups.Color Dim background
---@field light? Base16.Config.ColorGroups.Color Light background
---@field selection? Base16.Config.ColorGroups.Color Selection background
---@field cursor_line? Base16.Config.ColorGroups.Color Cursor line background
---@field cursor_column? Base16.Config.ColorGroups.Color Cursor column background

---@class Base16.Config.ColorGroups.Foregrounds
---@field normal? Base16.Config.ColorGroups.Color Normal foreground
---@field dim? Base16.Config.ColorGroups.Color Dim foreground
---@field dark? Base16.Config.ColorGroups.Color Dark foreground
---@field light? Base16.Config.ColorGroups.Color Light foreground
---@field bright? Base16.Config.ColorGroups.Color Bright foreground
---@field comment? Base16.Config.ColorGroups.Color Comment foreground
---@field line_number? Base16.Config.ColorGroups.Color Line number foreground

---@class Base16.Config.ColorGroups.Syntax
---@field variable? Base16.Config.ColorGroups.Color Variable foreground
---@field constant? Base16.Config.ColorGroups.Color Constant foreground
---@field string? Base16.Config.ColorGroups.Color String foreground
---@field number? Base16.Config.ColorGroups.Color Number foreground
---@field boolean? Base16.Config.ColorGroups.Color Boolean foreground
---@field keyword? Base16.Config.ColorGroups.Color Keyword foreground
---@field function_name? Base16.Config.ColorGroups.Color Function name foreground
---@field type? Base16.Config.ColorGroups.Color Type foreground
---@field comment? Base16.Config.ColorGroups.Color Comment foreground
---@field operator? Base16.Config.ColorGroups.Color Operator foreground
---@field delimiter? Base16.Config.ColorGroups.Color Delimiter foreground

---@class Base16.Config.ColorGroups.States
---@field error? Base16.Config.ColorGroups.Color Error foreground
---@field warning? Base16.Config.ColorGroups.Color Warning foreground
---@field info? Base16.Config.ColorGroups.Color Info foreground
---@field hint? Base16.Config.ColorGroups.Color Hint foreground
---@field success? Base16.Config.ColorGroups.Color Success foreground

---@class Base16.Config.ColorGroups.Diff
---@field added? Base16.Config.ColorGroups.Color Added foreground
---@field removed? Base16.Config.ColorGroups.Color Removed foreground
---@field changed? Base16.Config.ColorGroups.Color Changed foreground
---@field text? Base16.Config.ColorGroups.Color Text foreground

---@class Base16.Config.ColorGroups.Search
---@field match? Base16.Config.ColorGroups.Color Match foreground
---@field current? Base16.Config.ColorGroups.Color Current match foreground
---@field incremental? Base16.Config.ColorGroups.Color Incremental match foreground

---@class Base16.Config.Styles
---@field italic? boolean Enable italics
---@field bold? boolean Enable bold text
---@field transparency? boolean Transparent background
---@field dim_inactive_windows? boolean Dim inactive windows
---@field blends? Base16.Config.Styles.Blends Blend values to override

---@class Base16.Config.Styles.Blends
---@field subtle? number barely visible backgrounds (10%)
---@field medium? number noticeable but not distracting (15%)
---@field strong? number prominent highlights (25%)
---@field super? number very prominent highlights (50%)

---@class Base16.Config.Plugins
---@field enable_all? boolean Enable all plugins
---@field nvim_mini_mini_icons? boolean Enable Mini Icons
---@field nvim_mini_mini_diff? boolean Enable Mini Diff
---@field nvim_mini_mini_files? boolean Enable Mini Files
---@field nvim_mini_mini_pick? boolean Enable Mini Pick
---@field meandering_programmer_render_markdown_nvim? boolean Enable Render Markdown
---@field y3owk1n_undo_glow_nvim? boolean Enable Undo Glow
---@field saghen_blink_cmp? boolean Enable Blink Cmp
---@field magicduck_grug_far_nvim? boolean Enable Grug Far
---@field folke_which_key_nvim? boolean Enable Which Key
---@field folke_flash_nvim? boolean Enable Flash

---@alias Base16.Group.Raw
---| '"base00"' # Default background (Semantic Alias: bg)
---| '"base01"' # Lighter Background (Used for status bars) (Semantic Alias: bg_dim)
---| '"base02"' # Selection background (Semantic Alias: bg_light)
---| '"base03"' # Comments, Invisibles, Line Highlighting (Semantic Alias: fg_dim)
---| '"base04"' # Dark Foreground (Used for status bars) (Semantic Alias: fg_dark)
---| '"base05"' # Default Foreground, Caret, Delimiters, Operators (Semantic Alias: fg)
---| '"base06"' # Light foreground (Semantic Alias: fg_light)
---| '"base07"' # The Lightest Foreground (Semantic Alias: fg_bright)
---| '"base08"' # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted (Semantic Alias: red)
---| '"base09"' # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Semantic Alias: orange)
---| '"base0A"' # Classes, Markup Bold, Search Text Background (Semantic Alias: yellow)
---| '"base0B"' # Strings, Inherited Class, Markup Code, Diff Inserted (Semantic Alias: green)
---| '"base0C"' # Support, Regular Expressions, Escape Characters, Markup Quotes (Semantic Alias: cyan)
---| '"base0D"' # Functions, Methods, Attribute IDs, Headings (Semantic Alias: blue)
---| '"base0E"' # Keywords, Storage, Selector, Markup Italic, Diff Changed (Semantic Alias: purple)
---| '"base0F"' # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Semantic Alias: brown)

---@alias Base16.Group.Alias
---| '"bg"' # Default background (Raw Base16: base00)
---| '"bg_dim"' # Lighter Background (Used for status bars) (Raw Base16: base01)
---| '"bg_light"' # Selection background (Raw Base16: base02)
---| '"fg_dim"' # Comments, Invisibles, Line Highlighting (Raw Base16: base03)
---| '"fg_dark"' # Dark Foreground (Used for status bars) (Raw Base16: base04)
---| '"fg"' # Default Foreground, Caret, Delimiters, Operators (Raw Base16: base05)
---| '"fg_light"' # Light foreground (Raw Base16: base06)
---| '"fg_bright"' # The Lightest Foreground (Raw Base16: base07)
---| '"red"' # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted (Raw Base16: base08)
---| '"orange"' # Integers, Boolean, Constants, XML Attributes, Markup Link Url (Raw Base16: base09)
---| '"yellow"' # Classes, Markup Bold, Search Text Background (Raw Base16: base0A)
---| '"green"' # Strings, Inherited Class, Markup Code, Diff Insert
---| '"cyan"' # Support, Regular Expressions, Escape Characters, Markup Quotes (Raw Base16: base0C)
---| '"blue"' # Functions, Methods, Attribute IDs, Headings (Raw Base16: base0D)
---| '"purple"' # Keywords, Storage, Selector, Markup Italic, Diff Changed (Raw Base16: base0E)
---| '"brown"' # Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?> (Raw Base16: base0F)

-- ------------------------------------------------------------------
-- Utility
-- ------------------------------------------------------------------

---@private
---Convert a color name to RGB values
---@param color string
---@return number[] rgb The RGB values
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

---@type table<string, string>
local blend_cache = {}

---@private
---@param fg string Foreground color
---@param bg string Background color
---@param alpha number Between 0 (background) and 1 (foreground)
---@return string blended_color The blended color as hex
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

---@private
---Check if a plugin is enabled in config
---@param name string The plugin name
local function has_plugin(name)
  local plugin = M.config.plugins[name]

  if not plugin then
    return M.config.plugins.enable_all or false
  end

  return plugin
end

---Reference `https://github.com/tinted-theming/home/blob/main/styling.md`
---@type table<Base16.Group.Alias, Base16.Group.Raw>
local base16_alias = {
  bg = "base00", -- Default background
  bg_dim = "base01", -- Lighter Background (Used for status bars)
  bg_light = "base02", -- Selection background
  fg_dim = "base03", -- Comments, Invisibles, Line Highlighting
  fg_dark = "base04", -- Dark Foreground (Used for status bars)
  fg = "base05", -- Default Foreground, Caret, Delimiters, Operators
  fg_light = "base06", -- Light foreground
  fg_bright = "base07", -- The Lightest Foreground
  red = "base08", -- Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
  orange = "base09", -- Integers, Boolean, Constants, XML Attributes, Markup Link Url
  yellow = "base0A", -- Classes, Markup Bold, Search Text Background
  green = "base0B", -- Strings, Inherited Class, Markup Code, Diff Inserted
  cyan = "base0C", -- Support, Regular Expressions, Escape Characters, Markup Quotes
  blue = "base0D", -- Functions, Methods, Attribute IDs, Headings
  purple = "base0E", -- Keywords, Storage, Selector, Markup Italic, Diff Changed
  brown = "base0F", -- Deprecated, Opening/Closing Embedded Language Tags, e.g. <?php ?>
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

---@private
---Helper function for consistent transparency handling
---@param normal_bg string The normal background color
---@param transparent_override? string The transparent override color
---@return string The background color
local function get_bg(normal_bg, transparent_override)
  if M.config.styles.transparency then
    return transparent_override or "NONE"
  end
  return normal_bg
end

---@private
---Get a color from the standardized color groups
---@param group string The color group (e.g., "syntax", "states")
---@param key string The color key within the group
---@param c table<Base16.Group.Alias, string> The semantic color palette
---@return string color The resolved color
local function get_group_color(group, key, c)
  local color_group = M.config.color_groups[group]
  if not color_group or not color_group[key] then
    return c.fg -- fallback
  end

  local color_value = color_group[key]
  if type(color_value) == "function" then
    return color_value(c)
  else
    return c[color_value]
  end
end

-- ------------------------------------------------------------------
-- Highlight Setup Functions
-- ------------------------------------------------------------------

---@private
---Setup editor highlights (UI elements)
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_editor_hl(highlights, c)
  -- Normal and floating windows
  highlights.Normal = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.NormalFloat = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.NormalNC = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = M.config.styles.dim_inactive_windows and get_group_color("backgrounds", "dim", c)
      or get_bg(get_group_color("backgrounds", "normal", c)),
    blend = M.config.styles.dim_inactive_windows and M.config.styles.blends.super or nil,
  }
  highlights.NormalSB = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = get_group_color("backgrounds", "normal", c),
  }

  -- Cursor and lines
  highlights.Cursor = {
    fg = get_group_color("backgrounds", "normal", c),
    bg = get_group_color("foregrounds", "normal", c),
    bold = M.config.styles.bold,
  }
  highlights.lCursor = { link = "Cursor" }
  highlights.CursorIM = { link = "Cursor" }
  highlights.CursorLine = { bg = get_group_color("backgrounds", "cursor_line", c) }
  highlights.CursorColumn = { bg = get_bg(get_group_color("backgrounds", "cursor_column", c)) }
  highlights.CursorLineNr = {
    fg = get_group_color("syntax", "constant", c),
    bg = get_bg(get_group_color("backgrounds", "cursor_line", c)),
    bold = M.config.styles.bold,
  }
  highlights.LineNr = { fg = get_group_color("foregrounds", "line_number", c) }
  highlights.SignColumn = { fg = get_group_color("foregrounds", "dim", c) }
  highlights.SignColumnSB = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.ColorColumn = { bg = get_bg(get_group_color("backgrounds", "dim", c)) }

  -- Window separators
  highlights.VertSplit = { fg = get_group_color("foregrounds", "dim", c) }
  highlights.WinSeparator = { fg = get_group_color("foregrounds", "dim", c) }
  highlights.WinBar = {
    fg = get_group_color("foregrounds", "dark", c),
    bg = get_bg(get_group_color("backgrounds", "light", c)),
  }
  highlights.WinBarNC = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_bg(get_group_color("backgrounds", "dim", c)),
  }

  -- Folding and concealing
  highlights.Folded = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_bg(get_group_color("backgrounds", "dim", c)),
  }
  highlights.FoldColumn = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.Conceal = { fg = get_group_color("foregrounds", "dim", c) }

  -- Visual selection
  highlights.Visual = { bg = get_group_color("backgrounds", "selection", c) }
  highlights.VisualNOS = { link = "Visual" }
  highlights.MatchParen = {
    bg = get_group_color("backgrounds", "selection", c),
    bold = M.config.styles.bold,
  }

  -- Search
  highlights.Search = {
    fg = get_group_color("backgrounds", "normal", c),
    bg = get_group_color("search", "match", c),
    bold = M.config.styles.bold,
  }
  highlights.CurSearch = {
    fg = get_group_color("backgrounds", "normal", c),
    bg = get_group_color("search", "current", c),
    bold = M.config.styles.bold,
  }
  highlights.IncSearch = { link = "CurSearch" }
  highlights.Substitute = { link = "IncSearch" }
end

---@private
---Setup popup menu highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_popup_hl(highlights, c)
  highlights.Pmenu = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.PmenuSel = {
    bg = get_group_color("backgrounds", "selection", c),
    bold = M.config.styles.bold,
  }
  highlights.PmenuSbar = { bg = get_group_color("backgrounds", "light", c) }
  highlights.PmenuThumb = { bg = get_group_color("foregrounds", "dark", c) }
  highlights.PmenuKind = {
    fg = get_group_color("syntax", "keyword", c),
    bold = M.config.styles.bold,
  }
  highlights.PmenuKindSel = {
    fg = get_group_color("syntax", "keyword", c),
    bg = blend(get_group_color("syntax", "function_name", c), get_group_color("backgrounds", "normal", c), 0.3),
    bold = M.config.styles.bold,
  }
  highlights.PmenuExtra = { fg = get_group_color("foregrounds", "dim", c) }
  highlights.PmenuExtraSel = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = blend(get_group_color("syntax", "function_name", c), get_group_color("backgrounds", "normal", c), 0.3),
  }
end

---@private
---Setup status and tab line highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_statusline_hl(highlights, c)
  -- Tabline
  highlights.TabLine = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_bg(get_group_color("backgrounds", "dim", c)),
  }
  highlights.TabLineFill = { bg = get_bg(get_group_color("backgrounds", "dim", c)) }
  highlights.TabLineSel = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = get_group_color("backgrounds", "light", c),
    bold = M.config.styles.bold,
  }

  -- Statusline
  highlights.StatusLine = {
    fg = get_group_color("foregrounds", "dark", c),
    bg = get_group_color("backgrounds", "dim", c),
  }
  highlights.StatusLineNC = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_group_color("backgrounds", "dim", c),
  }
end

---@private
---Setup message highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_message_hl(highlights, c)
  highlights.ErrorMsg = {
    fg = get_group_color("states", "error", c),
    bold = M.config.styles.bold,
  }
  highlights.WarningMsg = {
    fg = get_group_color("states", "warning", c),
    bold = M.config.styles.bold,
  }
  highlights.MoreMsg = { fg = get_group_color("states", "success", c) }
  highlights.ModeMsg = { fg = get_group_color("states", "success", c) }
  highlights.Question = { fg = get_group_color("states", "info", c) }
  highlights.NvimInternalError = { link = "ErrorMsg" }
end

---@private
---Setup diff highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_diff_hl(highlights, c)
  highlights.DiffAdd = { fg = get_group_color("diff", "added", c) }
  highlights.DiffChange = { fg = get_group_color("diff", "changed", c) }
  highlights.DiffDelete = { fg = get_group_color("diff", "removed", c) }
  highlights.DiffText = { fg = get_group_color("diff", "text", c) }
end

---@private
---Setup spelling highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_spelling_hl(highlights, c)
  highlights.SpellBad = { sp = get_group_color("states", "error", c), undercurl = true }
  highlights.SpellCap = { sp = get_group_color("states", "info", c), undercurl = true }
  highlights.SpellLocal = { sp = get_group_color("syntax", "operator", c), undercurl = true }
  highlights.SpellRare = { sp = get_group_color("states", "hint", c), undercurl = true }
end

---@private
---Setup syntax highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_syntax_hl(highlights, c)
  -- Comments
  highlights.Comment = {
    fg = get_group_color("syntax", "comment", c),
    italic = M.config.styles.italic,
  }

  -- Constants
  highlights.Constant = { fg = get_group_color("syntax", "constant", c) }
  highlights.String = {
    fg = get_group_color("syntax", "string", c),
    italic = M.config.styles.italic,
  }
  highlights.Character = { fg = get_group_color("syntax", "constant", c) }
  highlights.Number = { fg = get_group_color("syntax", "number", c) }
  highlights.Boolean = {
    fg = get_group_color("syntax", "boolean", c),
    italic = M.config.styles.italic,
  }
  highlights.Float = { fg = get_group_color("syntax", "number", c) }

  -- Identifiers
  highlights.Identifier = {
    fg = get_group_color("syntax", "variable", c),
    italic = M.config.styles.italic,
  }
  highlights.Function = {
    fg = get_group_color("syntax", "function_name", c),
    bold = M.config.styles.bold,
  }

  -- Keywords and statements
  highlights.Statement = {
    fg = get_group_color("syntax", "function_name", c),
    bold = M.config.styles.bold,
  }
  highlights.Conditional = { fg = get_group_color("syntax", "keyword", c) }
  highlights.Repeat = { fg = get_group_color("syntax", "keyword", c) }
  highlights.Label = { fg = get_group_color("syntax", "operator", c) }
  highlights.Operator = { fg = get_group_color("syntax", "operator", c) }
  highlights.Keyword = {
    fg = get_group_color("syntax", "keyword", c),
    bold = M.config.styles.bold,
    italic = M.config.styles.italic,
  }
  highlights.Exception = { fg = get_group_color("states", "error", c) }

  -- Preprocessor
  highlights.PreProc = { link = "PreCondit" }
  highlights.Include = { fg = get_group_color("syntax", "function_name", c) }
  highlights.Define = { fg = get_group_color("syntax", "keyword", c) }
  highlights.Macro = { fg = get_group_color("states", "error", c) }
  highlights.PreCondit = { fg = get_group_color("syntax", "keyword", c) }

  -- Types
  highlights.Type = {
    fg = get_group_color("syntax", "type", c),
    bold = M.config.styles.bold,
  }
  highlights.StorageClass = { fg = get_group_color("syntax", "type", c) }
  highlights.Structure = { fg = get_group_color("syntax", "operator", c) }
  highlights.Typedef = { link = "Type" }

  -- Specials
  highlights.Special = { fg = get_group_color("syntax", "operator", c) }
  highlights.SpecialChar = { link = "Special" }
  highlights.Tag = { fg = get_group_color("syntax", "operator", c) }
  highlights.Delimiter = { fg = get_group_color("syntax", "delimiter", c) }
  highlights.SpecialComment = { link = "Special" }
  highlights.Debug = { fg = get_group_color("states", "error", c) }

  -- Misc
  highlights.Underlined = { underline = true }
  highlights.Bold = { bold = M.config.styles.bold }
  highlights.Italic = { italic = M.config.styles.italic }
  highlights.Ignore = { fg = get_group_color("foregrounds", "dim", c) }
  highlights.Error = {
    fg = get_group_color("states", "error", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.Todo = {
    fg = get_group_color("syntax", "type", c),
    bg = get_bg(get_group_color("backgrounds", "dim", c)),
  }

  -- Health check colors
  highlights.healthError = { fg = get_group_color("states", "error", c) }
  highlights.healthSuccess = { fg = get_group_color("states", "success", c) }
  highlights.healthWarning = { fg = get_group_color("states", "warning", c) }
end

---@private
---Setup treesitter highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_treesitter_hl(highlights, c)
  -- Variables
  highlights["@variable"] = { fg = get_group_color("syntax", "variable", c) }
  highlights["@variable.builtin"] = {
    fg = get_group_color("states", "error", c),
    bold = M.config.styles.bold,
    italic = M.config.styles.italic,
  }
  highlights["@variable.parameter"] = { fg = get_group_color("syntax", "constant", c) }
  highlights["@variable.parameter.builtin"] = {
    fg = get_group_color("syntax", "keyword", c),
    bold = M.config.styles.bold,
  }
  highlights["@variable.member"] = { fg = get_group_color("syntax", "operator", c) }

  -- Constants
  highlights["@constant"] = {
    fg = get_group_color("syntax", "constant", c),
    bold = M.config.styles.bold,
  }
  highlights["@constant.builtin"] = {
    fg = get_group_color("states", "error", c),
    bold = M.config.styles.bold,
  }
  highlights["@constant.macro"] = { fg = get_group_color("syntax", "constant", c) }

  -- Modules and labels
  highlights["@module"] = { fg = get_group_color("syntax", "variable", c) }
  highlights["@module.builtin"] = {
    fg = get_group_color("syntax", "variable", c),
    bold = M.config.styles.bold,
  }
  highlights["@label"] = { link = "Label" }

  -- Strings
  highlights["@string"] = { link = "String" }
  highlights["@string.regexp"] = { fg = get_group_color("syntax", "keyword", c) }
  highlights["@string.escape"] = { fg = get_group_color("syntax", "function_name", c) }
  highlights["@string.special"] = { link = "String" }
  highlights["@string.special.symbol"] = { link = "Identifier" }
  highlights["@string.special.url"] = { fg = get_group_color("syntax", "keyword", c) }

  -- Numbers and characters
  highlights["@character"] = { link = "Character" }
  highlights["@character.special"] = { link = "Character" }
  highlights["@boolean"] = { link = "Boolean" }
  highlights["@number"] = { link = "Number" }
  highlights["@number.float"] = { link = "Number" }
  highlights["@float"] = { link = "Number" }

  -- Types
  highlights["@type"] = { fg = get_group_color("syntax", "constant", c) }
  highlights["@type.builtin"] = {
    fg = get_group_color("syntax", "constant", c),
    bold = M.config.styles.bold,
    italic = M.config.styles.italic,
  }
  highlights["@type.definition"] = { link = "Type" }

  -- Attributes and properties
  highlights["@attribute"] = { fg = get_group_color("syntax", "type", c) }
  highlights["@attribute.builtin"] = {
    fg = get_group_color("syntax", "type", c),
    bold = M.config.styles.bold,
  }
  highlights["@property"] = { fg = get_group_color("syntax", "operator", c) }

  -- Functions
  highlights["@function"] = { link = "Function" }
  highlights["@function.builtin"] = {
    fg = get_group_color("syntax", "operator", c),
    bold = M.config.styles.bold,
  }
  highlights["@function.call"] = { link = "Function" }
  highlights["@function.macro"] = { link = "Function" }
  highlights["@function.method"] = { link = "Function" }
  highlights["@function.method.call"] = { link = "Function" }

  -- Operators and constructors
  highlights["@constructor"] = { fg = get_group_color("foregrounds", "dim", c) }
  highlights["@operator"] = { link = "Operator" }

  -- Keywords (comprehensive mapping)
  highlights["@keyword"] = { link = "Keyword" }
  highlights["@keyword.modifier"] = { link = "Function" }
  highlights["@keyword.type"] = { link = "Function" }
  highlights["@keyword.coroutine"] = { link = "Function" }
  highlights["@keyword.function"] = {
    fg = get_group_color("syntax", "keyword", c),
    bold = M.config.styles.bold,
  }
  highlights["@keyword.operator"] = { fg = get_group_color("syntax", "keyword", c) }
  highlights["@keyword.import"] = { link = "Include" }
  highlights["@keyword.repeat"] = { link = "Repeat" }
  highlights["@keyword.return"] = {
    fg = get_group_color("states", "error", c),
    bold = M.config.styles.bold,
  }
  highlights["@keyword.debug"] = { link = "Exception" }
  highlights["@keyword.exception"] = { link = "Exception" }
  highlights["@keyword.conditional"] = { link = "Conditional" }
  highlights["@keyword.conditional.ternary"] = { link = "Operator" }
  highlights["@keyword.directive"] = { link = "PreProc" }
  highlights["@keyword.directive.define"] = { link = "Define" }
  highlights["@keyword.export"] = {
    fg = get_group_color("syntax", "function_name", c),
    italic = M.config.styles.italic,
  }

  -- Punctuation
  highlights["@punctuation.delimiter.regex"] = { link = "@string.regexp" }
  highlights["@punctuation.delimiter"] = { link = "Delimiter" }
  highlights["@punctuation.bracket"] = { link = "@constructor" }
  highlights["@punctuation.special"] = { link = "Special" }

  -- Comments with semantic highlighting
  highlights["@comment"] = { link = "Comment" }
  highlights["@comment.documentation"] = { link = "Comment" }
  highlights["@comment.todo"] = {
    fg = get_group_color("syntax", "type", c),
    bg = blend(get_group_color("syntax", "type", c), get_group_color("backgrounds", "normal", c), 0.1),
    bold = M.config.styles.bold,
  }
  highlights["@comment.note"] = {
    fg = get_group_color("states", "info", c),
    bg = blend(get_group_color("states", "info", c), get_group_color("backgrounds", "normal", c), 0.1),
    bold = M.config.styles.bold,
  }
  highlights["@comment.warning"] = {
    fg = get_group_color("states", "warning", c),
    bg = blend(get_group_color("states", "warning", c), get_group_color("backgrounds", "normal", c), 0.1),
    bold = M.config.styles.bold,
  }
  highlights["@comment.error"] = {
    fg = get_group_color("states", "error", c),
    bg = blend(get_group_color("states", "error", c), get_group_color("backgrounds", "normal", c), 0.1),
    bold = M.config.styles.bold,
  }

  -- LSP semantic tokens
  highlights["@lsp.type.comment"] = {}
  highlights["@lsp.type.comment.c"] = { link = "@comment" }
  highlights["@lsp.type.comment.cpp"] = { link = "@comment" }
  highlights["@lsp.type.enum"] = { link = "@type" }
  highlights["@lsp.type.interface"] = { link = "@type" }
  highlights["@lsp.type.keyword"] = { link = "@keyword" }
  highlights["@lsp.type.namespace"] = { link = "@module" }
  highlights["@lsp.type.namespace.python"] = { link = "@variable" }
  highlights["@lsp.type.parameter"] = { link = "@variable.parameter" }
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

---@private
---Setup markdown highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_markdown_hl(highlights, c)
  -- Markdown headings with consistent color progression
  local heading_colors = {
    get_group_color("states", "error", c), -- H1: red
    get_group_color("syntax", "constant", c), -- H2: orange
    get_group_color("syntax", "type", c), -- H3: yellow
    get_group_color("states", "success", c), -- H4: green
    get_group_color("syntax", "operator", c), -- H5: cyan
    get_group_color("states", "info", c), -- H6: blue
  }

  for i = 1, 6 do
    highlights["markdownH" .. i] = {
      fg = heading_colors[i],
      bold = M.config.styles.bold,
    }
    highlights["markdownH" .. i .. "Delimiter"] = {
      fg = heading_colors[i],
      bold = M.config.styles.bold,
    }
    highlights["@markup.heading." .. i .. ".markdown"] = { link = "markdownH" .. i }
    highlights["@markup.heading." .. i .. ".marker.markdown"] = { link = "markdownH" .. i .. "Delimiter" }
  end

  -- Markdown links and formatting
  highlights.markdownLinkText = { link = "markdownUrl" }
  highlights.markdownUrl = {
    fg = get_group_color("syntax", "keyword", c),
    sp = get_group_color("syntax", "keyword", c),
    underline = true,
  }

  -- Markup elements
  highlights["@markup.strong"] = { bold = M.config.styles.bold }
  highlights["@markup.italic"] = { italic = M.config.styles.italic }
  highlights["@markup.strikethrough"] = { strikethrough = true }
  highlights["@markup.underline"] = { underline = true }
  highlights["@markup.heading"] = {
    fg = get_group_color("syntax", "operator", c),
    bold = M.config.styles.bold,
  }
  highlights["@markup.quote"] = { fg = get_group_color("foregrounds", "dim", c) }
  highlights["@markup.list"] = { fg = get_group_color("states", "error", c) }
  highlights["@markup.link"] = {
    fg = get_group_color("syntax", "keyword", c),
    underline = true,
  }
  highlights["@markup.raw"] = { fg = get_group_color("syntax", "string", c) }

  -- Diff markup
  highlights["@diff.plus"] = { fg = get_group_color("diff", "added", c) }
  highlights["@diff.minus"] = { fg = get_group_color("diff", "removed", c) }
  highlights["@diff.delta"] = { fg = get_group_color("states", "hint", c) }

  -- Tags
  highlights["@tag"] = { link = "Tag" }
  highlights["@tag.attribute"] = { fg = get_group_color("syntax", "keyword", c) }
  highlights["@tag.delimiter"] = { fg = get_group_color("syntax", "delimiter", c) }
end

---@private
---Setup diagnostics highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_diagnostics_hl(highlights, c)
  -- Diagnostic messages
  highlights.DiagnosticError = {
    fg = get_group_color("states", "error", c),
    bold = M.config.styles.bold,
  }
  highlights.DiagnosticWarn = {
    fg = get_group_color("states", "warning", c),
    bold = M.config.styles.bold,
  }
  highlights.DiagnosticInfo = {
    fg = get_group_color("states", "info", c),
    bold = M.config.styles.bold,
  }
  highlights.DiagnosticHint = {
    fg = get_group_color("states", "hint", c),
    bold = M.config.styles.bold,
  }

  -- Diagnostic underlines
  highlights.DiagnosticUnderlineError = {
    sp = get_group_color("states", "error", c),
    undercurl = true,
  }
  highlights.DiagnosticUnderlineWarn = {
    sp = get_group_color("states", "warning", c),
    undercurl = true,
  }
  highlights.DiagnosticUnderlineInfo = {
    sp = get_group_color("states", "info", c),
    undercurl = true,
  }
  highlights.DiagnosticUnderlineHint = {
    sp = get_group_color("states", "hint", c),
    undercurl = true,
  }
end

---@private
---Setup LSP highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_lsp_hl(highlights, c)
  highlights.LspReferenceText = { bg = get_group_color("backgrounds", "light", c) }
  highlights.LspReferenceRead = { bg = get_group_color("backgrounds", "light", c) }
  highlights.LspReferenceWrite = { bg = get_group_color("backgrounds", "light", c) }
end

---@private
---Setup terminal highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_terminal_hl(highlights, c)
  highlights.Terminal = {
    fg = get_group_color("foregrounds", "normal", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.TermCursor = {
    fg = get_group_color("backgrounds", "normal", c),
    bg = get_group_color("states", "success", c),
  }
  highlights.TermCursorNC = {
    fg = get_group_color("backgrounds", "normal", c),
    bg = get_group_color("foregrounds", "dim", c),
  }
end

---@private
---Setup floating window highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_float_hl(highlights, c)
  highlights.FloatBorder = {
    fg = get_group_color("foregrounds", "dim", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
  }
  highlights.FloatShadow = { bg = get_group_color("backgrounds", "light", c) }
  highlights.FloatTitle = {
    fg = get_group_color("syntax", "operator", c),
    bg = get_bg(get_group_color("backgrounds", "normal", c)),
    bold = M.config.styles.bold,
    italic = M.config.styles.italic,
  }
  highlights.FloatShadowThrough = { link = "FloatShadow" }
  highlights.WildMenu = { link = "IncSearch" }
  highlights.Directory = {
    fg = get_group_color("syntax", "operator", c),
    bold = M.config.styles.bold,
  }
  highlights.Title = {
    fg = get_group_color("syntax", "operator", c),
    bold = M.config.styles.bold,
  }
end

---@private
---Setup plugin integration highlights
---@param highlights table<string, vim.api.keyset.highlight>
---@param c table<Base16.Group.Alias, string>
local function setup_integration_hl(highlights, c)
  -- Mini Icons - standardized color mapping
  if has_plugin("nvim_mini_mini_icons") then
    highlights.MiniIconsAzure = { fg = get_group_color("syntax", "operator", c) }
    highlights.MiniIconsBlue = { fg = get_group_color("states", "info", c) }
    highlights.MiniIconsCyan = { fg = get_group_color("syntax", "operator", c) }
    highlights.MiniIconsGreen = { fg = get_group_color("states", "success", c) }
    highlights.MiniIconsGrey = { fg = get_group_color("foregrounds", "dim", c) }
    highlights.MiniIconsOrange = { fg = get_group_color("states", "warning", c) }
    highlights.MiniIconsPurple = { fg = get_group_color("states", "hint", c) }
    highlights.MiniIconsRed = { fg = get_group_color("states", "error", c) }
    highlights.MiniIconsYellow = { fg = get_group_color("syntax", "type", c) }
  end

  -- Mini Diff
  if has_plugin("nvim_mini_mini_diff") then
    highlights.MiniDiffAdd = { link = "DiffAdd" }
    highlights.MiniDiffChange = { link = "DiffChange" }
    highlights.MiniDiffDelete = { link = "DiffDelete" }
    highlights.MiniDiffSignAdd = { link = "DiffAdd" }
    highlights.MiniDiffSignChange = { link = "DiffChange" }
    highlights.MiniDiffSignDelete = { link = "DiffDelete" }
  end

  -- Mini Files
  if has_plugin("nvim_mini_mini_files") then
    highlights.MiniFilesBorder = { link = "FloatBorder" }
    highlights.MiniFilesBorderModified = {
      fg = get_group_color("states", "warning", c),
      bg = get_bg(get_group_color("backgrounds", "normal", c)),
    }
    highlights.MiniFilesCursorLine = { link = "CursorLine" }
    highlights.MiniFilesDirectory = { link = "Directory" }
    highlights.MiniFilesFile = { fg = get_group_color("foregrounds", "normal", c) }
    highlights.MiniFilesNormal = { link = "NormalFloat" }
    highlights.MiniFilesTitle = { link = "FloatTitle" }
  end

  -- Mini Pick
  if has_plugin("nvim_mini_mini_pick") then
    highlights.MiniPickBorder = { link = "FloatBorder" }
    highlights.MiniPickBorderBusy = {
      fg = get_group_color("states", "warning", c),
      bg = get_bg(get_group_color("backgrounds", "normal", c)),
    }
    highlights.MiniPickBorderText = { bg = get_group_color("foregrounds", "dim", c) }
    highlights.MiniPickIconDirectory = { link = "Directory" }
    highlights.MiniPickIconFile = { link = "MiniPickNormal" }
    highlights.MiniPickHeader = {
      fg = get_group_color("states", "hint", c),
      bg = get_bg(get_group_color("backgrounds", "normal", c)),
    }
    highlights.MiniPickMatchCurrent = { link = "CursorLine" }
    highlights.MiniPickMatchMarked = { link = "Visual" }
    highlights.MiniPickMatchRanges = { fg = get_group_color("syntax", "operator", c) }
    highlights.MiniPickNormal = { link = "NormalFloat" }
    highlights.MiniPickPreviewLine = { link = "CursorLine" }
    highlights.MiniPickPreviewRegion = { link = "IncSearch" }
    highlights.MiniPickPrompt = {
      bg = get_bg(get_group_color("backgrounds", "normal", c)),
      bold = M.config.styles.bold,
    }
  end

  -- Render Markdown
  if has_plugin("meandering_programmer_render_markdown_nvim") then
    local heading_colors = {
      get_group_color("states", "error", c), -- H1: red
      get_group_color("syntax", "constant", c), -- H2: orange
      get_group_color("syntax", "type", c), -- H3: yellow
      get_group_color("states", "success", c), -- H4: green
      get_group_color("syntax", "operator", c), -- H5: cyan
      get_group_color("states", "info", c), -- H6: blue
    }

    for i = 1, 6 do
      highlights["RenderMarkdownH" .. i .. "Bg"] = {
        bg = heading_colors[i],
        blend = M.config.styles.blends.medium,
      }
    end

    highlights.RenderMarkdownBullet = { fg = get_group_color("syntax", "constant", c) }
    highlights.RenderMarkdownChecked = { fg = get_group_color("syntax", "operator", c) }
    highlights.RenderMarkdownUnchecked = { fg = get_group_color("foregrounds", "dim", c) }
    highlights.RenderMarkdownCode = { bg = get_group_color("backgrounds", "dim", c) }
    highlights.RenderMarkdownCodeInline = {
      bg = get_group_color("backgrounds", "dim", c),
      fg = get_group_color("foregrounds", "normal", c),
    }
    highlights.RenderMarkdownQuote = { fg = get_group_color("foregrounds", "dim", c) }
    highlights.RenderMarkdownTableFill = { link = "Conceal" }
    highlights.RenderMarkdownTableHead = { fg = get_group_color("foregrounds", "dim", c) }
    highlights.RenderMarkdownTableRow = { fg = get_group_color("foregrounds", "dim", c) }
  end

  -- Undo Glow
  if has_plugin("y3owk1n_undo_glow_nvim") then
    highlights.UgUndo = {
      bg = get_group_color("states", "error", c),
      blend = M.config.styles.blends.strong,
    }
    highlights.UgRedo = {
      bg = get_group_color("states", "success", c),
      blend = M.config.styles.blends.strong,
    }
    highlights.UgYank = {
      bg = get_group_color("syntax", "constant", c),
      blend = M.config.styles.blends.strong,
    }
    highlights.UgPaste = {
      bg = get_group_color("syntax", "operator", c),
      blend = M.config.styles.blends.strong,
    }
    highlights.UgSearch = {
      bg = get_group_color("states", "info", c),
      blend = M.config.styles.blends.strong,
    }
    highlights.UgComment = {
      bg = get_group_color("syntax", "type", c),
      blend = M.config.styles.blends.strong,
    }
    highlights.UgCursor = { bg = get_group_color("backgrounds", "light", c) }
  end

  -- Blink Cmp
  if has_plugin("saghen_blink_cmp") then
    highlights.BlinkCmpDoc = { link = "Normal" }
    highlights.BlinkCmpDocSeparator = { fg = get_group_color("foregrounds", "dim", c) }
    highlights.BlinkCmpDocBorder = { link = "FloatBorder" }
    highlights.BlinkCmpGhostText = { link = "Comment" }
    highlights.BlinkCmpLabel = { link = "Comment" }
    highlights.BlinkCmpLabelDeprecated = { link = "Comment", strikethrough = true }
    highlights.BlinkCmpLabelMatch = {
      fg = get_group_color("foregrounds", "normal", c),
      bold = M.config.styles.bold,
    }
    highlights.BlinkCmpDefault = { link = "Normal" }

    -- Completion item kinds with consistent semantic colors
    local cmp_kinds = {
      Text = "states.info",
      Method = "syntax.operator",
      Function = "syntax.operator",
      Constructor = "syntax.operator",
      Field = "states.info",
      Variable = "syntax.constant",
      Class = "syntax.type",
      Interface = "syntax.type",
      Module = "syntax.operator",
      Property = "syntax.operator",
      Unit = "states.info",
      Value = "states.error",
      Keyword = "syntax.keyword",
      Snippet = "syntax.constant",
      Color = "states.error",
      File = "syntax.operator",
      Reference = "states.error",
      Folder = "syntax.operator",
      Enum = "syntax.operator",
      EnumMember = "syntax.operator",
      Constant = "syntax.constant",
      Struct = "syntax.operator",
      Event = "syntax.operator",
      Operator = "syntax.operator",
      TypeParameter = "syntax.keyword",
    }

    for kind, color_path in pairs(cmp_kinds) do
      local group_name, color_name = color_path:match("([^.]+)%.([^.]+)")
      highlights["BlinkCmpKind" .. kind] = {
        fg = get_group_color(group_name, color_name, c),
      }
    end

    highlights.BlinkCmpMenuBorder = { link = "FloatBorder" }
  end

  -- Grug Far
  if has_plugin("magicduck_grug_far_nvim") then
    highlights.GrugFarHelpHeader = { fg = get_group_color("states", "info", c) }
    highlights.GrugFarHelpHeaderKey = { fg = get_group_color("syntax", "constant", c) }
    highlights.GrugFarHelpWinActionKey = { fg = get_group_color("syntax", "constant", c) }
    highlights.GrugFarHelpWinActionPrefix = { fg = get_group_color("syntax", "operator", c) }
    highlights.GrugFarHelpWinActionText = { fg = get_group_color("states", "info", c) }
    highlights.GrugFarHelpWinHeader = { link = "FloatTitle" }
    highlights.GrugFarInputLabel = { fg = get_group_color("syntax", "operator", c) }
    highlights.GrugFarInputPlaceholder = { link = "Comment" }
    highlights.GrugFarResultsActionMessage = { fg = get_group_color("syntax", "operator", c) }
    highlights.GrugFarResultsChangeIndicator = { fg = get_group_color("diff", "changed", c) }
    highlights.GrugFarResultsRemoveIndicator = { fg = get_group_color("diff", "removed", c) }
    highlights.GrugFarResultsAddIndicator = { fg = get_group_color("diff", "added", c) }
    highlights.GrugFarResultsHeader = { fg = get_group_color("states", "info", c) }
    highlights.GrugFarResultsLineNo = { fg = get_group_color("states", "hint", c) }
    highlights.GrugFarResultsLineColumn = { link = "GrugFarResultsLineNo" }
    highlights.GrugFarResultsMatch = { link = "IncSearch" }
    highlights.GrugFarResultsPath = { fg = get_group_color("syntax", "operator", c) }
    highlights.GrugFarResultsStats = { fg = get_group_color("states", "hint", c) }
  end

  -- Which Key
  if has_plugin("folke_which_key_nvim") then
    highlights.WhichKey = {
      fg = get_group_color("states", "info", c),
      bold = M.config.styles.bold,
    }
    highlights.WhichKeyBorder = { link = "FloatBorder" }
    highlights.WhichKeyDesc = {
      fg = get_group_color("foregrounds", "normal", c),
      italic = M.config.styles.italic,
    }
    highlights.WhichKeyFloat = { link = "NormalFloat" }
    highlights.WhichKeyGroup = {
      fg = get_group_color("states", "hint", c),
      bold = M.config.styles.bold,
    }
    highlights.WhichKeyIcon = { fg = get_group_color("states", "info", c) }

    -- Link to standardized icon colors
    highlights.WhichKeyIconAzure = { link = "MiniIconsAzure" }
    highlights.WhichKeyIconBlue = { link = "MiniIconsBlue" }
    highlights.WhichKeyIconCyan = { link = "MiniIconsCyan" }
    highlights.WhichKeyIconGreen = { link = "MiniIconsGreen" }
    highlights.WhichKeyIconGrey = { link = "MiniIconsGrey" }
    highlights.WhichKeyIconOrange = { link = "MiniIconsOrange" }
    highlights.WhichKeyIconPurple = { link = "MiniIconsPurple" }
    highlights.WhichKeyIconRed = { link = "MiniIconsRed" }
    highlights.WhichKeyIconYellow = { link = "MiniIconsYellow" }

    highlights.WhichKeyNormal = { link = "Normal" }
    highlights.WhichKeySeparator = { fg = get_group_color("foregrounds", "dim", c) }
    highlights.WhichKeyTitle = { link = "FloatTitle" }
    highlights.WhichKeyValue = { fg = get_group_color("syntax", "constant", c) }
  end

  -- Flash
  if has_plugin("folke_flash_nvim") then
    highlights.FlashLabel = {
      fg = get_group_color("backgrounds", "normal", c),
      bg = get_group_color("states", "error", c),
    }
  end
end

---@private
---Apply all highlights with standardized grouping
---@return nil
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

  ---@type table<string, vim.api.keyset.highlight>
  local highlights = {}

  -- Apply highlights in logical groups
  setup_editor_hl(highlights, c)
  setup_popup_hl(highlights, c)
  setup_statusline_hl(highlights, c)
  setup_message_hl(highlights, c)
  setup_diff_hl(highlights, c)
  setup_spelling_hl(highlights, c)
  setup_syntax_hl(highlights, c)
  setup_treesitter_hl(highlights, c)
  setup_markdown_hl(highlights, c)
  setup_diagnostics_hl(highlights, c)
  setup_lsp_hl(highlights, c)
  setup_terminal_hl(highlights, c)
  setup_float_hl(highlights, c)
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
          -- Allow referencing base16 colors like "red" or "base08"
          if type(value) == "string" and value:match("^base[0-9A-F][0-9A-F]$") then
            parsed[key] = raw[value]
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

  -- Apply all highlights with blend processing
  for group, opts in pairs(highlights) do
    -- Call before_highlight hook if provided
    if M.config.before_highlight then
      M.config.before_highlight(group, opts, c)
    end

    -- Process blend values
    if opts.blend ~= nil and (opts.blend >= 0 and opts.blend <= 100) and opts.bg ~= nil then
      local bg_hex = c[opts.bg] or opts.bg
      ---@diagnostic disable-next-line: param-type-mismatch
      opts.bg = blend(bg_hex, opts.blend_on or c.bg, opts.blend / 100)
    end

    opts.blend = nil
    ---@diagnostic disable-next-line: inject-field
    opts.blend_on = nil

    ---@diagnostic disable-next-line: undefined-field
    if opts._nvim_blend ~= nil then
      ---@diagnostic disable-next-line: undefined-field
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
  styles = {
    italic = false,
    bold = false,
    transparency = false,
    dim_inactive_windows = false,
    blends = {
      subtle = 10,
      medium = 15,
      strong = 25,
      super = 50,
    },
  },
  plugins = {
    enable_all = false,
  },
  color_groups = {
    -- Background variations
    backgrounds = {
      normal = "bg",
      dim = "bg_dim",
      light = "bg_light",
      selection = "bg_light",
      cursor_line = function(c)
        return blend(c.bg_light, c.bg, 0.6)
      end,
      cursor_column = function(c)
        return blend(c.bg_dim, c.bg, 0.3)
      end,
    },

    -- Foreground variations
    foregrounds = {
      normal = "fg",
      dim = "fg_dim",
      dark = "fg_dark",
      light = "fg_light",
      bright = "fg_bright",
      comment = "fg_dark",
      line_number = function(c)
        return blend(c.fg_dim, c.bg, 0.7)
      end,
    },

    -- Semantic colors for syntax
    syntax = {
      variable = "fg",
      constant = "orange",
      string = "green",
      number = "orange",
      boolean = "orange",
      keyword = "purple",
      function_name = "blue",
      type = "yellow",
      comment = "fg_dark",
      operator = "cyan",
      delimiter = "brown",
    },

    -- UI state colors
    states = {
      error = "red",
      warning = "orange",
      info = "blue",
      hint = "purple",
      success = "green",
    },

    -- Diff colors
    diff = {
      added = "green",
      removed = "red",
      changed = "orange",
      text = "blue",
    },

    -- Search and selection
    search = {
      match = "yellow",
      current = "orange",
      incremental = "orange",
    },
  },
}

-- Cache for the semantic palette
local _cached_colors = nil

---Setup the base16 plugin
---@param user_config? Base16.Config
---@return nil
---@usage [[
---require("base16").setup({
---  colors = { base00 = "#1f1f28", base01 = "#2a2a37", ... }
---})
---@usage ]]
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

  -- Validate plugins
  if not M.config.plugins or type(M.config.plugins) ~= "table" then
    error("plugins table is required in setup(). Please provide plugins.")
  end

  did_setup = true
end

---Setup the colorscheme
---@usage [[
---vim.cmd.colorscheme("base16")
---@usage ]]
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

---Get a color from standardized groups
---@param group string The color group name
---@param key string The color key within the group
---@return string|nil color The resolved color, or nil if not found
function M.get_group_color(group, key)
  local colors = M.colors()
  if not colors then
    return nil
  end
  return get_group_color(group, key, colors)
end

---Blend two colors together
---@param fg_color string Foreground color (hex)
---@param bg_color string Background color (hex)
---@param alpha number Alpha value between 0 (background) and 1 (foreground)
---@return string blended_color The blended color as hex
function M.blend_colors(fg_color, bg_color, alpha)
  return blend(fg_color, bg_color, alpha)
end

---Invalidate the color cache (useful when colors are updated)
---@private
function M._invalidate_cache()
  _cached_colors = nil
end

---Validate color configuration
---@param colors table<Base16.Group.Raw, string> The colors to validate
---@return boolean valid True if all required colors are present
---@return string[] missing Array of missing color keys
function M.validate_colors(colors)
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

  local missing = {}
  for _, color in ipairs(required_colors) do
    if not colors[color] then
      table.insert(missing, color)
    end
  end

  return #missing == 0, missing
end

return M
