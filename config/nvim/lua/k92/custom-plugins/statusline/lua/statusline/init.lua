---@class Statusline
---@field config Statusline.Config
---@field defaults Statusline.Config
local M = {}

---@class Statusline.Config
---@field padding? Statusline.Config.Padding Padding configuration for left/right sides of the statusline
---@field component_separator? string Separator between components
---@field hide_in_special_buffers? boolean Hide statusline in special buffers
---@field layout Statusline.Layout? Component layout configuration
---@field mode Statusline.ModeConfig? Mode component configuration
---@field fileinfo Statusline.FileinfoConfig? Fileinfo component configuration
---@field git Statusline.GitConfig? Git component configuration
---@field diff Statusline.DiffConfig? Diff component configuration
---@field diagnostics Statusline.DiagnosticsConfig? Diagnostics component configuration
---@field lsp Statusline.LspConfig? LSP component configuration
---@field position Statusline.PositionConfig? Position component configuration
---@field progress Statusline.ProgressConfig? Progress component configuration
---@field encoding Statusline.EncodingConfig? Encoding component configuration
---@field fileformat Statusline.FileformatConfig? Fileformat component configuration
---@field filetype Statusline.FiletypeConfig? Filetype component configuration
---@field warp Statusline.WarpConfig? Warp component configuration
---@field post_setup_fn? fun(config: Statusline.Config) Callback function to run after setup

---@class Statusline.Config.Padding
---@field left? number Padding on left side
---@field right? number Padding on right side

---@class Statusline.Config.General
---@field enabled? boolean Enable statusline
---@field prefix? string Text before statusline
---@field suffix? string Text after statusline
---@field hl? string Highlight group for the whole component

---@class Statusline.Layout
---@field left string[] List of component names for left side
---@field center string[] List of component names for center
---@field right string[] List of component names for right side

---@class Statusline.ModeConfig : Statusline.Config.General
---@field mode_map? table<string, string> Mapping of mode codes to display names

---@class Statusline.FileinfoConfig : Statusline.Config.General
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

---@class Statusline.GitConfig : Statusline.Config.General
---@field icon? string Git branch icon
---@field max_length? number Maximum branch name length (0 for no limit)

---@class Statusline.DiffConfig : Statusline.Config.General
---@field icons? Statusline.DiffIcons Diff change icons
---@field separator? string Separator between diff stats

---@class Statusline.DiffIcons
---@field add? string Icon for additions
---@field delete? string Icon for deletions
---@field change? string Icon for changes

---@class Statusline.DiagnosticsConfig : Statusline.Config.General
---@field icons? Statusline.DiagnosticIcons Diagnostic severity icons
---@field separator? string Separator between diagnostic counts
---@field show_info? boolean Show info diagnostics
---@field show_hint? boolean Show hint diagnostics

---@class Statusline.DiagnosticIcons
---@field error? string Error diagnostic icon
---@field warn? string Warning diagnostic icon
---@field info? string Info diagnostic icon
---@field hint? string Hint diagnostic icon

---@class Statusline.LspConfig : Statusline.Config.General
---@field icon? string LSP icon
---@field detail_prefix? string Text before lsp details after icon
---@field detail_suffix? string Text after lsp details
---@field separator? string Separator between server names
---@field max_servers? number Maximum servers to show (0 for no limit)

---@class Statusline.PositionConfig : Statusline.Config.General
---@field show_line? boolean Show line number
---@field show_col? boolean Show column number
---@field show_total? boolean Show total lines
---@field separator? string Separator between position parts

---@class Statusline.ProgressConfig : Statusline.Config.General
---@field use_bar? boolean Use progress bar instead of percentage
---@field bar_length? number Length of progress bar
---@field bar_fill? string Character for filled bar sections
---@field bar_empty? string Character for empty bar sections

---@class Statusline.EncodingConfig : Statusline.Config.General
---@field hide_default? boolean Hide if encoding is default (utf-8)

---@class Statusline.FileformatConfig : Statusline.Config.General
---@field hide_default? boolean Hide if format is default (unix)
---@field icons? table<string, string> Icons for different formats

---@class Statusline.FiletypeConfig : Statusline.Config.General
---@field unnamed_text? string Text for buffers without filetype

---@class Statusline.WarpConfig : Statusline.Config.General
---@field icon? string Warp icon

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

---Check if current buffer is valid for statusline display
---@return boolean valid True if buffer should show statusline components
local function is_valid_buffer()
  return vim.bo.buftype == "" and vim.fn.bufname() ~= ""
end

---Check if current buffer is a special buffer type
---@return boolean is_special True if buffer is special (help, qf, etc.)
local function is_special_buffer()
  local bt = vim.bo.buftype
  local ft = vim.bo.filetype
  return bt ~= "" or ft == "help" or ft == "qf" or ft == "man"
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

---Wrap text with statusline highlight group
---@param text string
---@param hl string?
---@return string
function M.with_hl(text, hl)
  if not hl or hl == "" or text == "" then
    return text
  end
  return "%#" .. hl .. "#" .. text .. "%*"
end

-- ------------------------------------------------------------------
-- Components
-- ------------------------------------------------------------------
---@type table<string, fun(config: Statusline.Config): string>
local components = {}

-- Mode component
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
      table.insert(parts, "%#StatuslineDiffAdd#" .. config.diff.icons.add .. changes.add)
    end
    if changes.delete > 0 then
      table.insert(parts, "%#StatuslineDiffDelete#" .. config.diff.icons.delete .. changes.delete)
    end
    if changes.change > 0 then
      table.insert(parts, "%#StatuslineDiffChange#" .. config.diff.icons.change .. changes.change)
    end

    local result = table.concat(parts, config.diff.separator)
    return result ~= "" and M.with_hl((config.diff.prefix .. result .. config.diff.suffix)) or ""
  end, "")
end

-- Diagnostics component
---@param config Statusline.Config
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
      table.insert(parts, "%#StatuslineDiagnosticsError#" .. config.diagnostics.icons.error .. counts.error)
    end
    if counts.warn > 0 then
      table.insert(parts, "%#StatuslineDiagnosticsWarn#" .. config.diagnostics.icons.warn .. counts.warn)
    end
    if config.diagnostics.show_info and counts.info > 0 then
      table.insert(parts, "%#StatuslineDiagnosticsInfo#" .. config.diagnostics.icons.info .. counts.info)
    end
    if config.diagnostics.show_hint and counts.hint > 0 then
      table.insert(parts, "%#StatuslineDiagnosticsHint#" .. config.diagnostics.icons.hint .. counts.hint)
    end

    local result = table.concat(parts, config.diagnostics.separator)
    return result ~= "" and M.with_hl((config.diagnostics.prefix .. result .. config.diagnostics.suffix)) or ""
  end, "")
end

-- LSP component
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param config Statusline.Config
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
---@param layout Statusline.Layout
---@return string statusline
local function render_layout(layout)
  local left = render_components(layout.left)
  local center = render_components(layout.center)
  local right = render_components(layout.right)

  -- Build the final statusline with %= anchors
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
-- Core Statusline Builder
-- ------------------------------------------------------------------
---Build the complete statusline string
---@return string statusline Complete statusline string
function M.build_statusline()
  if is_special_buffer() and M.config.hide_in_special_buffers then
    return " %f%m%r%h%w%="
  end

  local statusline = render_layout(M.config.layout)

  if statusline == "" then
    return M.original_statusline
  end

  return string.rep(" ", M.config.padding.left) .. statusline .. string.rep(" ", M.config.padding.right)
end

-- Function to be called by statusline
---@return string statusline Complete statusline for vim statusline option
function M.get_statusline()
  return M.build_statusline()
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
---Set up autocmds for statusline refresh
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("CustomStatusline", { clear = true })

  local events = {
    "ModeChanged",
    "BufEnter",
    "BufWritePost",
    "FileChangedShellPost",
    "LspAttach",
    "LspDetach",
    "DiagnosticChanged",
    "WinEnter",
    "WinLeave",
  }

  vim.api.nvim_create_autocmd(events, {
    group = group,
    callback = function()
      vim.cmd("redrawstatus")
    end,
  })

  -- Git-related events
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "FugitiveChanged", "GitSignsUpdate" },
    callback = function()
      vim.cmd("redrawstatus")
    end,
  })
end

-- ------------------------------------------------------------------
-- Configuration
-- ------------------------------------------------------------------
---@type Statusline.Config
M.defaults = {
  -- Global settings
  padding = { left = 0, right = 0 },
  component_separator = " ",
  hide_in_special_buffers = true,

  -- Layout configuration
  layout = {
    left = { "mode", "git", "diff" },
    center = { "fileinfo" },
    right = { "diagnostics", "lsp", "position", "progress" },
  },

  -- Component configurations
  mode = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "StatuslineMode",
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
    hl = "StatuslineFileInfo",
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
    hl = "StatuslineGit",
    icon = " ",
    max_length = 20,
  },

  diff = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "StatuslineDiff",
    icons = { add = "+", delete = "-", change = "~" },
    separator = " ",
  },

  diagnostics = {
    enabled = true,
    prefix = "",
    suffix = "",
    hl = "StatuslineDiagnostics",
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
    hl = "StatuslineLsp",
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
    hl = "StatuslinePosition",
    show_line = true,
    show_col = true,
    show_total = false,
    separator = ":",
  },

  progress = {
    enabled = true,
    prefix = "",
    suffix = "%",
    hl = "StatuslineProgress",
    use_bar = false,
    bar_length = 10,
    bar_fill = "█",
    bar_empty = "░",
  },

  encoding = {
    enabled = false,
    prefix = "[",
    suffix = "]",
    hl = "StatuslineEncoding",
    hide_default = false,
  },

  fileformat = {
    enabled = false,
    prefix = "[",
    suffix = "]",
    hl = "StatuslineFileformat",
    hide_default = true,
    icons = { unix = "", dos = "", mac = "" },
  },

  filetype = {
    enabled = false,
    prefix = "",
    suffix = "",
    hl = "StatuslineFiletype",
    unnamed_text = "text",
  },

  warp = {
    enabled = false,
    prefix = "",
    suffix = "",
    hl = "StatuslineWarp",
    icon = "󱐋 ",
  },
}

local did_setup = false

M.original_statusline = nil

---Setup the statusline with configuration
---@param user_config? table User configuration to merge with defaults
function M.setup(user_config)
  if did_setup then
    return
  end

  ---@diagnostic disable-next-line: undefined-field
  M.original_statusline = vim.opt.statusline:get()

  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  setup_autocmds()
  setup_highlight_groups()

  -- Set the statusline to use our function
  vim.opt.statusline = "%{%luaeval('require(\"statusline\").get_statusline()')%}"

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
---@param fn fun(config: Statusline.Config): string Component function that returns display string
---@param default_config? table Default config for component
---@example
---```lua
---local sm = require("statusline")
---
---sm.register_component("time", function(cfg)
---  return sm.with_hl(cfg.time.icon .. cfg.time.prefix .. os.date("%H:%M") .. cfg.time.suffix, cfg.time.hl)
---end, {)
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
      hl = "Statusline" .. name:gsub("^%l", string.upper),
    }, M.defaults[name] or default_config or {})
  end
end

return M
