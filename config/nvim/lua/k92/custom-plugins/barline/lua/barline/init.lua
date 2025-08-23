---@class Barline
---@field config Barline.Config
---@field defaults Barline.Config
local M = {}

-- track first setup
local did_setup = false

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Barline.Config
---@field component_separator? string Separator between components
---@field special_buftypes? string[] Hide lines in special buffer types
---@field show_default_line_in_special_buffers? boolean Hide lines in special buffers
---@field mode Barline.ModeConfig? Mode component configuration
---@field fileinfo Barline.FileinfoConfig? Fileinfo component configuration
---@field git Barline.GitConfig? Git component configuration
---@field diff Barline.DiffConfig? Diff component configuration
---@field diagnostics Barline.DiagnosticsConfig? Diagnostics component configuration
---@field lsp Barline.LspConfig? LSP component configuration
---@field position Barline.PositionConfig? Position component configuration
---@field progress Barline.ProgressConfig? Progress component configuration
---@field encoding Barline.EncodingConfig? Encoding component configuration
---@field fileformat Barline.FileformatConfig? Fileformat component configuration
---@field filetype Barline.FiletypeConfig? Filetype component configuration
---@field warp Barline.WarpConfig? Warp component configuration
---@field post_setup_fn? fun(config: Barline.Config) Callback function to run after setup
---@field statusline? Barline.DisplayConfig.Statusline
---@field winbar? Barline.DisplayConfig.Winbar
---@field tabline? Barline.DisplayConfig.Tabline

---@class Barline.DisplayConfig.Statusline : Barline.DisplayConfig
---@field is_global? boolean

---@class Barline.DisplayConfig.Winbar : Barline.DisplayConfig

---@class Barline.DisplayConfig.Tabline : Barline.DisplayConfig

---@class Barline.DisplayConfig
---@field enabled? boolean
---@field padding? Barline.Config.Padding Padding configuration for left/right sides of the line
---@field layout? Barline.Layout

---@class Barline.Config.Padding
---@field left? number Padding on left side
---@field right? number Padding on right side

---@class Barline.Config.General
---@field enabled? boolean Enable component
---@field prefix? string Text before component
---@field suffix? string Text after component
---@field hl? string Highlight group for the whole component

---@class Barline.Layout
---@field left? string[] List of component names for left side
---@field center? string[] List of component names for center
---@field right? string[] List of component names for right side

---@class Barline.ModeConfig : Barline.Config.General
---@field mode_map? table<string, string> Mapping of mode codes to display names

---@class Barline.FileinfoConfig : Barline.Config.General
---@field color_icon? boolean Color file icon based on dev icon settings
---@field show_icon? boolean Show file icon
---@field show_filename? boolean Show filename
---@field show_modified? boolean Show modified indicator
---@field show_readonly? boolean Show readonly indicator
---@field modified_icon? string Icon for modified files
---@field readonly_icon? string Icon for readonly files
---@field unnamed_text? string Text for unnamed buffers
---@field max_length? number Maximum filename length (0 for no limit)
---@field path_style? '"none"'|'"relative"'|'"absolute"'|'"shortened"'|'"basename"' How to show the file path

---@class Barline.GitConfig : Barline.Config.General
---@field icon? string Git branch icon
---@field max_length? number Maximum branch name length (0 for no limit)

---@class Barline.DiffConfig : Barline.Config.General
---@field icons? Barline.DiffIcons Diff change icons
---@field separator? string Separator between diff stats

---@class Barline.DiffIcons
---@field add? string Icon for additions
---@field delete? string Icon for deletions
---@field change? string Icon for changes

---@class Barline.DiagnosticsConfig : Barline.Config.General
---@field icons? Barline.DiagnosticIcons Diagnostic severity icons
---@field separator? string Separator between diagnostic counts
---@field show_info? boolean Show info diagnostics
---@field show_hint? boolean Show hint diagnostics

---@class Barline.DiagnosticIcons
---@field error? string Error diagnostic icon
---@field warn? string Warning diagnostic icon
---@field info? string Info diagnostic icon
---@field hint? string Hint diagnostic icon

---@class Barline.LspConfig : Barline.Config.General
---@field icon? string LSP icon
---@field detail_prefix? string Text before lsp details after icon
---@field detail_suffix? string Text after lsp details
---@field separator? string Separator between server names
---@field max_servers? number Maximum servers to show (0 for no limit)

---@class Barline.PositionConfig : Barline.Config.General
---@field show_line? boolean Show line number
---@field show_col? boolean Show column number
---@field show_total? boolean Show total lines
---@field separator? string Separator between position parts

---@class Barline.ProgressConfig : Barline.Config.General
---@field use_bar? boolean Use progress bar instead of percentage
---@field bar_length? number Length of progress bar
---@field bar_fill? string Character for filled bar sections
---@field bar_empty? string Character for empty bar sections

---@class Barline.EncodingConfig : Barline.Config.General
---@field hide_default? boolean Hide if encoding is default (utf-8)

---@class Barline.FileformatConfig : Barline.Config.General
---@field hide_default? boolean Hide if format is default (unix)
---@field icons? table<string, string> Icons for different formats

---@class Barline.FiletypeConfig : Barline.Config.General
---@field unnamed_text? string Text for buffers without filetype

---@class Barline.WarpConfig : Barline.Config.General
---@field icon? string Warp icon

---@alias Barline.DisplayType "statusline"|"winbar"|"tabline"

-- ------------------------------------------------------------------
-- Utilities
-- ------------------------------------------------------------------
---Safe function call with default fallback
---@param fn function Function to call safely
---@param default any Default value if function fails
---@return any result Result of function or default value
local function safe_call(fn, default)
  local ok, result = pcall(fn)
  return ok and result or default
end

---Check if current buffer is valid for line display
---@return boolean valid True if buffer should show line components
local function is_valid_buffer()
  return vim.bo.buftype == "" and vim.fn.bufname() ~= ""
end

---Check if current buffer is a special buffer type
---@return boolean is_special True if buffer is special (help, qf, etc.)
local function is_special_buffer()
  local special_ft = { "help", "qf", "man", "cmd" }

  special_ft = vim.tbl_deep_extend("force", special_ft, M.config.special_buftypes or {})

  local bt = vim.bo.buftype
  local ft = vim.bo.filetype
  return bt ~= "" or vim.tbl_contains(special_ft, ft)
end

---Truncate string to maximum length with ellipsis
---@param str string String to truncate
---@param max_len number Maximum length (0 for no limit)
---@return string truncated Truncated string
local function truncate_string(str, max_len)
  if max_len <= 0 or #str <= max_len then
    return str
  end
  return string.sub(str, 1, max_len - 1) .. "…"
end

---Wrap text with line highlight group
---@param text string
---@param hl string?
---@return string
function M.with_hl(text, hl)
  if not hl or hl == "" or text == "" then
    return text
  end
  return "%#" .. hl .. "#" .. text .. "%*"
end

local function set_statusline()
  if M.config.statusline.is_global then
    vim.opt.laststatus = 3
  else
    vim.opt.laststatus = 2
  end
  vim.opt.statusline = '%{%luaeval(\'require("barline").get_line("statusline")\')%}'
end

---@param to_default? boolean Whether to reset to default statusline
local function unset_statusline(to_default)
  vim.opt.laststatus = 0
  if to_default then
    vim.opt.statusline = M.original_statusline
  else
    vim.opt.statusline = ""
  end
end

local function set_winbar()
  vim.opt.winbar = '%{%luaeval(\'require("barline").get_line("winbar")\')%}'
end

local function unset_winbar(to_default)
  vim.opt.winbar = to_default and M.original_winbar or ""
end

local function set_tabline()
  vim.opt.showtabline = 2
  vim.opt.tabline = '%{%luaeval(\'require("barline").get_line("tabline")\')%}'
end

local function unset_tabline(to_default)
  vim.opt.showtabline = 0
  vim.opt.tabline = to_default and M.original_tabline or ""
end

-- ------------------------------------------------------------------
-- Components
-- ------------------------------------------------------------------
---@type table<string, fun(config: Barline.Config): string>
local components = {}

-- Mode component
---@param config Barline.Config
---@return string mode_display
function components.mode(config)
  if not config.mode.enabled then
    return ""
  end

  local mode_map = config.mode.mode_map
    or {
      n = "NORMAL",
      i = "INSERT",
      v = "VISUAL",
      V = "V-LINE",
      ["\22"] = "V-BLOCK", -- Ctrl-V
      c = "COMMAND",
      s = "SELECT",
      S = "S-LINE",
      ["\19"] = "S-BLOCK", -- Ctrl-S
      R = "REPLACE",
      r = "REPLACE",
      ["!"] = "SHELL",
      t = "TERMINAL",
    }

  local current_mode = vim.api.nvim_get_mode().mode
  local mode_name = mode_map[current_mode] or current_mode:upper()

  return M.with_hl(string.format("%s%s%s", config.mode.prefix, mode_name, config.mode.suffix), config.mode.hl)
end

-- File info component
---@param config Barline.Config
---@return string fileinfo_display
function components.fileinfo(config)
  if not config.fileinfo.enabled then
    return ""
  end

  local parts = {}

  if config.fileinfo.show_icon then
    local has_devicons, devicons = pcall(require, "nvim-web-devicons")
    if not has_devicons then
      return ""
    end
    local filename = vim.fn.expand("%:t")
    local extension = vim.fn.expand("%:e")
    local icon, icon_hl = devicons.get_icon(filename, extension, { default = true })

    if icon ~= "" then
      local part = config.fileinfo.color_icon and M.with_hl(icon, icon_hl) or icon
      table.insert(parts, part)
    end
  end

  if config.fileinfo.show_filename then
    local filepath
    if config.fileinfo.path_style == "absolute" then
      filepath = vim.fn.expand("%:p")
    elseif config.fileinfo.path_style == "relative" then
      filepath = vim.fn.expand("%:.")
    elseif config.fileinfo.path_style == "shortened" then
      filepath = vim.fn.pathshorten(vim.fn.expand("%:~:."))
    elseif config.fileinfo.path_style == "basename" then
      filepath = vim.fn.expand("%:t")
    else -- fallback "none" or invalid
      filepath = vim.fn.expand("%:t")
    end

    if filepath == "" then
      filepath = config.fileinfo.unnamed_text
    else
      filepath = truncate_string(filepath, config.fileinfo.max_length)
    end

    table.insert(parts, filepath)
  end

  if config.fileinfo.show_modified and vim.bo.modified then
    table.insert(parts, config.fileinfo.modified_icon)
  end

  if config.fileinfo.show_readonly and vim.bo.readonly then
    table.insert(parts, config.fileinfo.readonly_icon)
  end

  local result = table.concat(parts, " ")
  return result ~= "" and M.with_hl((config.fileinfo.prefix .. result .. config.fileinfo.suffix), config.fileinfo.hl)
    or ""
end

-- Git component
---@param config Barline.Config
---@return string git_display
function components.git(config)
  if not config.git.enabled or not is_valid_buffer() then
    return ""
  end

  return safe_call(function()
    local repo_info = vim.b.githead_summary
    local has_git = repo_info ~= nil and repo_info.head_name ~= nil

    if not has_git then
      return ""
    end

    local branch_name = repo_info.head_name
    branch_name = truncate_string(branch_name, config.git.max_length)

    return M.with_hl(
      string.format("%s%s%s%s", config.git.prefix, config.git.icon, branch_name, config.git.suffix),
      config.git.hl
    )
  end, "")
end

-- Diff component
---@param config Barline.Config
---@return string diff_display
function components.diff(config)
  if not config.diff.enabled or not is_valid_buffer() then
    return ""
  end

  return safe_call(function()
    local summary = vim.b.minidiff_summary
    if not summary then
      return ""
    end

    local changes = {
      add = summary.add or 0,
      delete = summary.delete or 0,
      change = summary.change or 0,
    }

    if changes.add + changes.delete + changes.change == 0 then
      return ""
    end

    local parts = {}
    if changes.add > 0 then
      table.insert(parts, "%#BarlineDiffAdd#" .. config.diff.icons.add .. changes.add)
    end
    if changes.delete > 0 then
      table.insert(parts, "%#BarlineDiffDelete#" .. config.diff.icons.delete .. changes.delete)
    end
    if changes.change > 0 then
      table.insert(parts, "%#BarlineDiffChange#" .. config.diff.icons.change .. changes.change)
    end

    local result = table.concat(parts, config.diff.separator)
    return result ~= "" and M.with_hl((config.diff.prefix .. result .. config.diff.suffix)) or ""
  end, "")
end

-- Diagnostics component
---@param config Barline.Config
---@return string diagnostics_display
function components.diagnostics(config)
  if not config.diagnostics.enabled then
    return ""
  end

  return safe_call(function()
    local diagnostics = vim.diagnostic.get(0)
    if not diagnostics or #diagnostics == 0 then
      return ""
    end

    local counts = { error = 0, warn = 0, info = 0, hint = 0 }
    for _, diag in ipairs(diagnostics) do
      local severity = diag.severity
      if severity == vim.diagnostic.severity.ERROR then
        counts.error = counts.error + 1
      elseif severity == vim.diagnostic.severity.WARN then
        counts.warn = counts.warn + 1
      elseif severity == vim.diagnostic.severity.INFO then
        counts.info = counts.info + 1
      elseif severity == vim.diagnostic.severity.HINT then
        counts.hint = counts.hint + 1
      end
    end

    local parts = {}
    if counts.error > 0 then
      table.insert(parts, "%#BarlineDiagnosticsError#" .. config.diagnostics.icons.error .. counts.error)
    end
    if counts.warn > 0 then
      table.insert(parts, "%#BarlineDiagnosticsWarn#" .. config.diagnostics.icons.warn .. counts.warn)
    end
    if config.diagnostics.show_info and counts.info > 0 then
      table.insert(parts, "%#BarlineDiagnosticsInfo#" .. config.diagnostics.icons.info .. counts.info)
    end
    if config.diagnostics.show_hint and counts.hint > 0 then
      table.insert(parts, "%#BarlineDiagnosticsHint#" .. config.diagnostics.icons.hint .. counts.hint)
    end

    local result = table.concat(parts, config.diagnostics.separator)
    return result ~= "" and M.with_hl((config.diagnostics.prefix .. result .. config.diagnostics.suffix)) or ""
  end, "")
end

-- LSP component
---@param config Barline.Config
---@return string lsp_display
function components.lsp(config)
  if not config.lsp.enabled then
    return ""
  end

  return safe_call(function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if not clients or #clients == 0 then
      return ""
    end

    local names = {}
    for _, server in pairs(clients) do
      if server and server.name then
        table.insert(names, server.name)
      end
    end

    if #names == 0 then
      return ""
    end

    table.sort(names)
    if config.lsp.max_servers > 0 and #names > config.lsp.max_servers then
      local shown = {}
      for i = 1, config.lsp.max_servers do
        table.insert(shown, names[i])
      end
      table.insert(shown, string.format("+%d", #names - config.lsp.max_servers))
      names = shown
    end

    return M.with_hl(
      string.format(
        "%s%s%s%s%s%s",
        config.lsp.prefix,
        config.lsp.icon,
        config.lsp.detail_prefix,
        table.concat(names, config.lsp.separator),
        config.lsp.detail_suffix,
        config.lsp.suffix
      ),
      config.lsp.hl
    )
  end, "")
end

-- Position component (line:col)
---@param config Barline.Config
---@return string position_display
function components.position(config)
  if not config.position.enabled then
    return ""
  end

  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local total_lines = vim.fn.line("$")

  local parts = {}
  if config.position.show_line then
    table.insert(parts, tostring(line))
  end
  if config.position.show_col then
    table.insert(parts, tostring(col))
  end
  if config.position.show_total then
    table.insert(parts, tostring(total_lines))
  end

  local result = table.concat(parts, config.position.separator)
  return result ~= "" and M.with_hl((config.position.prefix .. result .. config.position.suffix), config.position.hl)
    or ""
end

-- Progress component (percentage through file)
---@param config Barline.Config
---@return string progress_display
function components.progress(config)
  if not config.progress.enabled then
    return ""
  end

  local line = vim.fn.line(".")
  local total = vim.fn.line("$")
  local percent = total > 0 and math.floor((line / total) * 100) or 0

  if config.progress.use_bar then
    local bar_length = config.progress.bar_length
    local filled = math.floor((percent / 100) * bar_length)
    local empty = bar_length - filled
    local bar = string.rep(config.progress.bar_fill, filled) .. string.rep(config.progress.bar_empty, empty)
    return config.progress.prefix .. bar .. config.progress.suffix
  else
    return M.with_hl(
      string.format("%s%d%%%s", config.progress.prefix, percent, config.progress.suffix),
      config.progress.hl
    )
  end
end

-- File encoding
---@param config Barline.Config
---@return string encoding_display
function components.encoding(config)
  if not config.encoding.enabled then
    return ""
  end

  local encoding = vim.bo.fileencoding
  if encoding == "" then
    encoding = vim.o.encoding
  end

  -- Only show if different from default
  if config.encoding.hide_default and encoding == "utf-8" then
    return ""
  end

  return M.with_hl(config.encoding.prefix .. encoding:upper() .. config.encoding.suffix, config.encoding.hl)
end

-- File format (unix/dos/mac)
---@param config Barline.Config
---@return string fileformat_display
function components.fileformat(config)
  if not config.fileformat.enabled then
    return ""
  end

  local format = vim.bo.fileformat
  local icons = config.fileformat.icons or {
    unix = "unix",
    dos = "dos",
    mac = "mac",
  }

  -- Only show if different from default
  if config.fileformat.hide_default and format == "unix" then
    return ""
  end

  return M.with_hl(
    config.fileformat.prefix .. (icons[format] or format) .. config.fileformat.suffix,
    config.fileformat.hl
  )
end

-- Filetype
---@param config Barline.Config
---@return string filetype_display
function components.filetype(config)
  if not config.filetype.enabled then
    return ""
  end

  local ft = vim.bo.filetype
  if ft == "" then
    ft = config.filetype.unnamed_text
  end

  return M.with_hl(config.filetype.prefix .. ft .. config.filetype.suffix, config.filetype.hl)
end

-- Custom component for warp
---@param config Barline.Config
---@return string warp_display
function components.warp(config)
  if not config.warp.enabled then
    return ""
  end

  return safe_call(function()
    local warp_exists, warp = pcall(require, "warp")
    if not warp_exists or not warp or warp.count() < 1 then
      return ""
    end

    local item = warp.get_item_by_buf(0)
    local current = item and item.index or "-"
    local total = warp.count()

    return M.with_hl(
      string.format(
        "%s%s[%s/%s]%s",
        config.warp.prefix,
        config.warp.icon,
        tonumber(current) or "-",
        tonumber(total),
        config.warp.suffix
      ),
      config.warp.hl
    )
  end, "")
end

-- ------------------------------------------------------------------
-- Layout Rendering
-- ------------------------------------------------------------------

---Render a list of component names into a string
---@param component_names string[] List of component names
---@return string rendered Concatenated component string
local function render_components(component_names)
  local parts = {}
  for _, name in ipairs(component_names or {}) do
    local fn = components[name]
    if fn then
      local result = fn(M.config)
      if result ~= "" then
        table.insert(parts, result)
      end
    end
  end
  return table.concat(parts, M.config.component_separator)
end

---Render the whole layout declaratively
---@param layout Barline.Layout
---@return string line
local function render_layout(layout)
  local left = render_components(layout.left)
  local center = render_components(layout.center)
  local right = render_components(layout.right)

  -- Build the final line with %= anchors
  local chunks = {}

  if left ~= "" then
    table.insert(chunks, left)
  end
  if center ~= "" then
    table.insert(chunks, "%=" .. center)
  end
  if right ~= "" then
    table.insert(chunks, "%=" .. right)
  end

  return table.concat(chunks)
end

-- ------------------------------------------------------------------
-- Core Barline Builder
-- ------------------------------------------------------------------
---Build the complete line string
---@param display Barline.DisplayType Display mode
---@return string line Complete line string
function M.build_line(display)
  if is_special_buffer() and M.config.show_default_line_in_special_buffers then
    if display == "statusline" then
      return M.original_statusline
    elseif display == "winbar" then
      return M.original_winbar
    elseif display == "tabline" then
      return M.original_tabline
    end
  end

  ---@type Barline.DisplayConfig
  local current_display = M.config[display]

  local line = render_layout(current_display.layout)

  if line == "" then
    if display == "statusline" then
      return M.original_statusline
    elseif display == "winbar" then
      return M.original_winbar
    elseif display == "tabline" then
      return M.original_tabline
    end
  end

  local left_padding = current_display.padding.left and string.rep(" ", current_display.padding.left) or ""
  local right_padding = current_display.padding.right and string.rep(" ", current_display.padding.right) or ""

  return left_padding .. line .. right_padding
end

-- Function to be called by lines
---@param display Barline.DisplayType Display mode
---@return string statusline Complete statusline for vim statusline option
function M.get_line(display)
  return M.build_line(display)
end

--------------------------------------------------------------------------------
-- Highlight Groups
--------------------------------------------------------------------------------

---Setup default highlight groups (no colors, just links if desired)
local function setup_highlight_groups()
  local function ensure_hl(name)
    local ok = pcall(vim.api.nvim_get_hl, 0, { name = name })
    if not ok then
      vim.api.nvim_set_hl(0, name, {}) -- only create empty if missing
    end
  end

  -- auto-generate groups for user-registered components
  for _, def in pairs(M.defaults) do
    if type(def) == "table" then
      local hl = def.hl
      if hl then
        ensure_hl(hl)
      end
    end
  end
end

-- ------------------------------------------------------------------
-- Event Handlers
-- ------------------------------------------------------------------
---Set up autocmds for lines refresh
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("CustomBarline", { clear = true })

  local events = {
    "WinEnter",
    "WinLeave",
    "BufEnter",
    "BufLeave",
    "BufWritePost",
    "DiagnosticChanged",
  }

  vim.api.nvim_create_autocmd(events, {
    group = group,
    callback = function()
      if M.config.statusline.enabled or M.config.winbar.enabled then
        vim.cmd("redrawstatus")
      end
      if M.config.tabline.enabled then
        vim.cmd("redrawtabline")
      end
    end,
  })
end

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------
---@type Barline.Config
M.defaults = {
  -- Global settings
  component_separator = " ",
  show_default_line_in_special_buffers = true,

  -- Layout configuration
  statusline = {
    enabled = true,
    is_global = true,
    padding = { left = 0, right = 0 },
    layout = {
      left = { "mode", "git", "diff" },
      center = { "fileinfo" },
      right = { "diagnostics", "lsp", "position", "progress" },
    },
  },

  tabline = {
    enabled = false,
    padding = { left = 0, right = 0 },
    layout = {
      left = {},
      center = {},
      right = {},
    },
  },

  winbar = {
    enabled = false,
    padding = { left = 0, right = 0 },
    layout = {
      left = {},
      center = {},
      right = {},
    },
  },

  -- Component configurations
  mode = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlineMode",
    mode_map = {
      n = "NORMAL",
      i = "INSERT",
      v = "VISUAL",
      V = "V-LINE",
      ["\22"] = "V-BLOCK",
      c = "COMMAND",
      s = "SELECT",
      S = "S-LINE",
      ["\19"] = "S-BLOCK",
      R = "REPLACE",
      r = "REPLACE",
      ["!"] = "SHELL",
      t = "TERMINAL",
    },
  },

  fileinfo = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlineFileInfo",
    show_icon = true,
    color_icon = false,
    show_filename = true,
    show_modified = true,
    show_readonly = true,
    modified_icon = "",
    readonly_icon = "",
    unnamed_text = "[No Name]",
    max_length = 30,
    path_style = "relative", -- options: "none", "relative", "absolute", "shortened", "basename"
  },

  git = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlineGit",
    icon = " ",
    max_length = 20,
  },

  diff = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlineDiff",
    icons = { add = "+", delete = "-", change = "~" },
    separator = " ",
  },

  diagnostics = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlineDiagnostics",
    icons = {
      error = vim.diagnostic.config().signs.text[vim.diagnostic.severity.ERROR],
      warn = vim.diagnostic.config().signs.text[vim.diagnostic.severity.WARN],
      info = vim.diagnostic.config().signs.text[vim.diagnostic.severity.INFO],
      hint = vim.diagnostic.config().signs.text[vim.diagnostic.severity.HINT],
    },
    separator = " ",
    show_info = false,
    show_hint = false,
  },

  lsp = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlineLsp",
    detail_prefix = "",
    detail_suffix = "",
    icon = " ",
    separator = " ",
    max_servers = 3,
  },

  position = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "BarlinePosition",
    show_line = true,
    show_col = true,
    show_total = false,
    separator = ":",
  },

  progress = {
    enabled = true,
    prefix = "",
    suffix = "%",
    hl = "BarlineProgress",
    use_bar = false,
    bar_length = 10,
    bar_fill = "█",
    bar_empty = "░",
  },

  encoding = {
    enabled = false,
    prefix = "[",
    suffix = "]",
    hl = "BarlineEncoding",
    hide_default = false,
  },

  fileformat = {
    enabled = false,
    prefix = "[",
    suffix = "]",
    hl = "BarlineFileformat",
    hide_default = true,
    icons = { unix = "", dos = "", mac = "" },
  },

  filetype = {
    enabled = false,
    prefix = "",
    suffix = "",
    hl = "BarlineFiletype",
    unnamed_text = "text",
  },

  warp = {
    enabled = false,
    prefix = "",
    suffix = "",
    hl = "BarlineWarp",
    icon = "󱐋 ",
  },
}

M.original_statusline = nil
M.original_winbar = nil
M.original_tabline = nil

---Setup the barline with configuration
---@param user_config? table User configuration to merge with defaults
function M.setup(user_config)
  if did_setup then
    return
  end

  ---@diagnostic disable-next-line: undefined-field
  M.original_statusline = vim.opt.statusline:get()
  ---@diagnostic disable-next-line: undefined-field
  M.original_winbar = vim.opt.winbar:get()
  ---@diagnostic disable-next-line: undefined-field
  M.original_tabline = vim.opt.tabline:get()

  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  setup_autocmds()
  setup_highlight_groups()

  -- Set the statusline to use our function
  if M.config.statusline.enabled then
    set_statusline()
  end

  if M.config.winbar.enabled then
    set_winbar()
  end

  if M.config.tabline.enabled then
    set_tabline()
  end

  if M.config.post_setup_fn then
    M.config.post_setup_fn(M.config)
  end

  did_setup = true
end

-- ------------------------------------------------------------------
-- Utility functions
-- ------------------------------------------------------------------
---Toggle a component on/off at runtime
---@param component_name string Name of component to toggle
function M.toggle_component(component_name)
  if M.config[component_name] then
    M.config[component_name].enabled = not M.config[component_name].enabled
    vim.cmd("redrawstatus")
    vim.notify(
      string.format("Component '%s' %s", component_name, M.config[component_name].enabled and "enabled" or "disabled")
    )
  end
end

---@param display Barline.DisplayType
function M.toggle_display(display)
  if M.config[display].enabled then
    M.config[display].enabled = false
    if display == "statusline" then
      unset_statusline()
    end
    if display == "winbar" then
      unset_winbar()
    end
    if display == "tabline" then
      unset_tabline()
    end
    vim.cmd("redrawstatus")
    vim.cmd("redrawtabline")
    vim.notify(string.format("Display '%s' disabled", display))
  else
    M.config[display].enabled = true
    if display == "statusline" then
      set_statusline()
    end
    if display == "winbar" then
      set_winbar()
    end
    if display == "tabline" then
      set_tabline()
    end
    vim.cmd("redrawstatus")
    vim.cmd("redrawtabline")
    vim.notify(string.format("Display '%s' enabled", display))
  end
end

---Get debug information about all components
---@return table<string, {enabled: boolean, output: string}> debug_info
function M.debug_info()
  local info = {}
  for name, _ in pairs(components) do
    if M.config[name] then
      info[name] = {
        enabled = M.config[name].enabled,
        output = components[name](M.config),
      }
    end
  end
  return info
end

---Register custom components
---Must be called before setup
---@param name string Component name
---@param fn fun(config: Barline.Config): string Component function that returns display string
---@param default_config? table Default config for component
---@example
---```lua
---local bm = require("barline")
---
---bm.register_component("time", function(cfg)
---  return bm.with_hl(cfg.time.icon .. cfg.time.prefix .. os.date("%H:%M") .. cfg.time.suffix, cfg.time.hl)
---end, {
---  icon = "",
---  hl = "CurSearch",
---})
---```
function M.register_component(name, fn, default_config)
  components[name] = fn

  if not M.defaults[name] then
    M.defaults[name] = vim.tbl_deep_extend("force", {
      enabled = true,
      prefix = "",
      suffix = "",
      hl = "Barline" .. name:gsub("^%l", string.upper),
    }, M.defaults[name] or default_config or {})
  end
end

return M
