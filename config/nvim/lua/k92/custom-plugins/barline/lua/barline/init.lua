---@class Barline
---@field config Barline.Config
---@field defaults Barline.Config
local M = {}

-- track first setup
local did_setup = false

-- Cache for performance
local cache = {
  file_size = {},
}

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@class Barline.Config
---@field component_separator? string Separator between components
---@field conditions? Barline.Conditions Global conditions for showing statusline
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
---@field macro Barline.MacroConfig? Macro recording component configuration
---@field search Barline.SearchConfig? Search count component configuration
---@field post_setup_fn? fun(config: Barline.Config) Callback function to run after setup
---@field statusline? Barline.DisplayConfig.Statusline
---@field winbar? Barline.DisplayConfig.Winbar
---@field tabline? Barline.DisplayConfig.Tabline

---@class Barline.Conditions
---@field hide_in_width? number|nil
---@field hide_in_focus? boolean
---@field disabled_filetypes? string[]
---@field disabled_buftypes? string[]

---@class Barline.DisplayConfig.Statusline : Barline.DisplayConfig
---@field is_global? boolean

---@class Barline.DisplayConfig.Winbar : Barline.DisplayConfig

---@class Barline.DisplayConfig.Tabline : Barline.DisplayConfig

---@class Barline.DisplayConfig
---@field enabled? boolean
---@field padding? Barline.Config.Padding Padding configuration for left/right sides of the line
---@field layout? Barline.Layout
---@field conditions? fun(): boolean Custom condition function for this display

---@class Barline.Config.Padding
---@field left? number Padding on left side
---@field right? number Padding on right side

---@class Barline.Config.General
---@field enabled? boolean Enable component
---@field prefix? string Text before component
---@field suffix? string Text after component
---@field hl? string Highlight group for the whole component
---@field condition? fun(): boolean Custom condition function for this component

---@class Barline.Layout
---@field left? string[] List of component names for left side
---@field center? string[] List of component names for center
---@field right? string[] List of component names for right side

---@class Barline.ModeConfig : Barline.Config.General
---@field mode_map? table<string, string> Mapping of mode codes to display names
---@field show_mode_colors? boolean Use different colors for different modes

---@class Barline.FileinfoConfig : Barline.Config.General
---@field color_icon? boolean Color file icon based on dev icon settings
---@field show_icon? boolean Show file icon
---@field show_filename? boolean Show filename
---@field show_modified? boolean Show modified indicator
---@field show_readonly? boolean Show readonly indicator
---@field show_size? boolean Show file size
---@field modified_icon? string Icon for modified files
---@field readonly_icon? string Icon for readonly files
---@field unnamed_text? string Text for unnamed buffers
---@field max_length? number Maximum filename length (0 for no limit)
---@field path_style_below_max_length? '"none"'|'"relative"'|'"absolute"'|'"shortened"'|'"basename"' How to show the file path
---@field path_style_above_max_length? '"none"'|'"relative"'|'"absolute"'|'"shortened"'|'"basename"' How to show the file path

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

---@class Barline.MacroConfig : Barline.Config.General
---@field icon? string Macro recording icon
---@field recording_text? string Text to show when recording

---@class Barline.SearchConfig : Barline.Config.General
---@field icon? string Search icon

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

---Check global conditions
---@return boolean should_show True if statusline should be shown
local function check_conditions()
  local conditions = M.config.conditions
  if not conditions then
    return true
  end

  -- Check window width
  if conditions.hide_in_width and vim.api.nvim_win_get_width(0) < conditions.hide_in_width then
    return false
  end

  -- Check window focus
  if conditions.hide_in_focus and vim.api.nvim_get_current_win() ~= vim.fn.win_getid() then
    return false
  end

  -- Check disabled filetypes
  if conditions.disabled_filetypes and vim.tbl_contains(conditions.disabled_filetypes, vim.bo.filetype) then
    return false
  end

  -- Check disabled buftypes
  if conditions.disabled_buftypes and vim.tbl_contains(conditions.disabled_buftypes, vim.bo.buftype) then
    return false
  end

  return true
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

---Format file size
---@param size number Size in bytes
---@return string formatted Formatted size string
local function format_file_size(size)
  if size < 1024 then
    return size .. "B"
  elseif size < 1024 * 1024 then
    return string.format("%.1fK", size / 1024)
  elseif size < 1024 * 1024 * 1024 then
    return string.format("%.1fM", size / (1024 * 1024))
  else
    return string.format("%.1fG", size / (1024 * 1024 * 1024))
  end
end

---Wrap text with line highlight group
---@param text string
---@param hl string?
---@return string
function M.with_hl(text, hl)
  if not text or text == "" then
    return ""
  end
  if not hl or hl == "" then
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

local function set_winbar()
  vim.opt.winbar = '%{%luaeval(\'require("barline").get_line("winbar")\')%}'
end

local function set_tabline()
  vim.opt.showtabline = 2
  vim.opt.tabline = '%{%luaeval(\'require("barline").get_line("tabline")\')%}'
end

-- ------------------------------------------------------------------
-- Components
-- ------------------------------------------------------------------
---@type table<string, fun(config: Barline.Config): string>
local components = {}

---Check if a component should be rendered based on its condition
---@param component_config table Component configuration
---@return boolean should_render True if component should be rendered
local function should_render_component(component_config)
  if not component_config or not component_config.enabled then
    return false
  end

  if component_config.condition and not component_config.condition() then
    return false
  end

  return true
end

-- Mode component
---@param config Barline.Config
---@return string mode_display
function components.mode(config)
  if not should_render_component(config.mode) then
    return ""
  end

  local mode_map = config.mode.mode_map or {}

  local current_mode = vim.api.nvim_get_mode().mode
  local mode_name = mode_map[current_mode] or current_mode:upper()

  local hl_group = config.mode.hl
  if config.mode.show_mode_colors then
    local mode_colors = {
      n = "BarlineModeNormal",
      i = "BarlineModeInsert",
      v = "BarlineModeVisual",
      V = "BarlineModeVisual",
      ["\22"] = "BarlineModeVisual",
      c = "BarlineModeCommand",
      R = "BarlineModeReplace",
      r = "BarlineModeReplace",
      t = "BarlineModeTerminal",
      nt = "BarlineModeNTerminal",
    }
    hl_group = mode_colors[current_mode] or hl_group
  end

  local text = config.mode.prefix .. mode_name .. config.mode.suffix
  return M.with_hl(text, hl_group)
end

-- File info component
---@param config Barline.Config
---@return string fileinfo_display
function components.fileinfo(config)
  if not should_render_component(config.fileinfo) then
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
    if config.fileinfo.path_style_above_max_length == "absolute" then
      filepath = vim.fn.expand("%:p")
    elseif config.fileinfo.path_style_above_max_length == "relative" then
      filepath = vim.fn.expand("%:.")
    elseif config.fileinfo.path_style_above_max_length == "shortened" then
      filepath = vim.fn.pathshorten(vim.fn.expand("%:~:."))
    elseif config.fileinfo.path_style_above_max_length == "basename" then
      filepath = vim.fn.expand("%:t")
    else -- fallback "none" or invalid
      filepath = vim.fn.expand("%:t")
    end

    if filepath == "" then
      filepath = config.fileinfo.unnamed_text
    else
      if #filepath > config.fileinfo.max_length then
        if config.fileinfo.path_style_below_max_length == "absolute" then
          filepath = vim.fn.expand("%:p")
        elseif config.fileinfo.path_style_below_max_length == "relative" then
          filepath = vim.fn.expand("%:.")
        elseif config.fileinfo.path_style_below_max_length == "shortened" then
          filepath = vim.fn.pathshorten(vim.fn.expand("%:~:."))
        elseif config.fileinfo.path_style_below_max_length == "basename" then
          filepath = vim.fn.expand("%:t")
        end
      end
    end

    filepath = truncate_string(filepath or "", config.fileinfo.max_length)

    table.insert(parts, filepath)
  end

  if config.fileinfo.show_size then
    local bufnr = vim.api.nvim_get_current_buf()
    local size = cache.file_size[bufnr]
    if not size then
      local stat = vim.loop.fs_stat(vim.api.nvim_buf_get_name(bufnr))
      if stat then
        size = format_file_size(stat.size)
        cache.file_size[bufnr] = size
      end
    end
    if size then
      table.insert(parts, "(" .. size .. ")")
    end
  end

  if config.fileinfo.show_modified and vim.bo.modified then
    table.insert(parts, config.fileinfo.modified_icon)
  end

  if config.fileinfo.show_readonly and vim.bo.readonly then
    table.insert(parts, config.fileinfo.readonly_icon)
  end

  if #parts == 0 then
    return ""
  end

  local text = config.fileinfo.prefix .. table.concat(parts, " ") .. config.fileinfo.suffix
  return M.with_hl(text, config.fileinfo.hl)
end

-- Git component
---@param config Barline.Config
---@return string git_display
function components.git(config)
  if not should_render_component(config.git) or not is_valid_buffer() then
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

    local text = config.git.prefix .. config.git.icon .. branch_name .. config.git.suffix
    return M.with_hl(text, config.git.hl)
  end, "")
end

-- Diff component
---@param config Barline.Config
---@return string diff_display
function components.diff(config)
  if not should_render_component(config.diff) or not is_valid_buffer() then
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
  if not should_render_component(config.diagnostics) then
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
  if not should_render_component(config.lsp) then
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

-- Macro recording component
---@param config Barline.Config
---@return string macro_display
function components.macro(config)
  if not should_render_component(config.macro) then
    return ""
  end

  local recording = vim.fn.reg_recording()
  if recording == "" then
    return ""
  end

  local icon = config.macro.icon or "󰑋"
  local text = config.macro.recording_text or "REC"

  return M.with_hl(
    config.macro.prefix .. icon .. " " .. text .. " @" .. recording .. config.macro.suffix,
    config.macro.hl
  )
end

-- Search count component
---@param config Barline.Config
---@return string search_display
function components.search(config)
  if not should_render_component(config.search) then
    return ""
  end

  return safe_call(function()
    local search_count = vim.fn.searchcount({ maxcount = 999, timeout = 250 })
    if not search_count or search_count.current == 0 then
      return ""
    end

    local icon = config.search.icon or "󰍉"
    local text = string.format("%d/%d", search_count.current, search_count.total)

    return M.with_hl(config.search.prefix .. icon .. " " .. text .. config.search.suffix, config.search.hl)
  end, "")
end

-- Position component (line:col)
---@param config Barline.Config
---@return string position_display
function components.position(config)
  if not should_render_component(config.position) then
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
  if not should_render_component(config.progress) then
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
    return bar
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
  if not should_render_component(config.encoding) then
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
  if not should_render_component(config.fileformat) then
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
  if not should_render_component(config.filetype) then
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
  if not should_render_component(config.warp) then
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
      if result and result ~= "" then
        table.insert(parts, result)
      end
    end
  end
  return #parts > 0 and table.concat(parts, M.config.component_separator) or ""
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

  if left and left ~= "" then
    table.insert(chunks, left)
  end
  if center and center ~= "" then
    table.insert(chunks, "%=" .. center)
  end
  if right and right ~= "" then
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
  -- Check global conditions
  if not check_conditions() then
    return "HIDDEN"
  end

  -- Check display-specific conditions
  ---@type Barline.DisplayConfig
  local display_config = M.config[display]
  if display_config and display_config.conditions and not display_config.conditions() then
    return "HIDDEN"
  end

  local line = render_layout(display_config.layout)

  if line == "" then
    if display == "statusline" then
      return M.original_statusline
    elseif display == "winbar" then
      return M.original_winbar
    elseif display == "tabline" then
      return M.original_tabline
    end
  end

  local left_padding = display_config.padding.left and string.rep(" ", display_config.padding.left) or ""
  local right_padding = display_config.padding.right and string.rep(" ", display_config.padding.right) or ""

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
  ---@param name string
  ---@param hl_opts? vim.api.keyset.highlight
  local function ensure_hl(name, hl_opts)
    local ok = pcall(vim.api.nvim_get_hl, 0, { name = name })
    if not ok then
      vim.api.nvim_set_hl(0, name, hl_opts or {}) -- only create empty if missing
    end
  end

  -- auto-generate groups for registered components
  for _, def in pairs(M.defaults) do
    if type(def) == "table" then
      local hl = def.hl
      if hl then
        ensure_hl(hl)
      end
    end
  end

  ensure_hl("BarlineModeNormal")
  ensure_hl("BarlineModeInsert")
  ensure_hl("BarlineModeVisual")
  ensure_hl("BarlineModeCommand")
  ensure_hl("BarlineModeReplace")
  ensure_hl("BarlineModeTerminal")
  ensure_hl("BarlineModeNTerminal")

  ensure_hl("BarlineDiagnosticsError")
  ensure_hl("BarlineDiagnosticsWarn")
  ensure_hl("BarlineDiagnosticsInfo")
  ensure_hl("BarlineDiagnosticsHint")

  ensure_hl("BarlineDiffAdd")
  ensure_hl("BarlineDiffDelete")
  ensure_hl("BarlineDiffChange")
end

-- ------------------------------------------------------------------
-- Event Handlers
-- ------------------------------------------------------------------
---Set up autocmds for lines refresh
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("CustomBarline", { clear = true })

  local events = {
    "LspAttach",
    "LspDetach",
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

  -- Clear file size cache when buffer changes
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      cache.file_size[bufnr] = nil
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

  -- Global conditions
  conditions = {
    hide_in_width = nil,
    hide_in_focus = false,
    disabled_filetypes = {},
    disabled_buftypes = {},
  },

  -- Layout configuration
  statusline = {
    enabled = true,
    is_global = true,
    padding = { left = 0, right = 0 },
    layout = {
      left = { "mode", "git", "diff" },
      center = { "fileinfo" },
      right = { "macro", "search", "diagnostics", "lsp", "position", "progress" },
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
    show_size = false,
    modified_icon = "",
    readonly_icon = "",
    unnamed_text = "[No Name]",
    max_length = 60,
    path_style_above_max_length = "relative", -- options: "none", "relative", "absolute", "shortened", "basename"
    path_style_below_max_length = "shortened", -- options: "none", "relative", "absolute", "shortened", "basename"
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

  macro = {
    enabled = false,
    prefix = "",
    suffix = "",
    hl = "BarlineMacro",
    icon = "󰑋",
    recording_text = "REC",
  },

  search = {
    enabled = false,
    prefix = "",
    suffix = "",
    hl = "BarlineSearch",
    icon = "󰍉",
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
    if M.config.tabline.enabled then
      vim.cmd("redrawtabline")
    end
    vim.notify(
      string.format("Component '%s' %s", component_name, M.config[component_name].enabled and "enabled" or "disabled")
    )
  else
    vim.notify(string.format("Component '%s' not found", component_name), vim.log.levels.ERROR)
  end
end

---Toggle statusline visibility
function M.toggle_statusline()
  M.config.statusline.enabled = not M.config.statusline.enabled
  if M.config.statusline.enabled then
    set_statusline()
  else
    vim.opt.statusline = M.original_statusline
  end
  vim.notify(string.format("Statusline %s", M.config.statusline.enabled and "enabled" or "disabled"))
end

---Reload configuration and refresh
function M.reload()
  setup_highlight_groups()
  vim.cmd("redrawstatus")
  if M.config.tabline.enabled then
    vim.cmd("redrawtabline")
  end
  vim.notify("Barline reloaded")
end

---Clear all caches
function M.clear_cache()
  cache.file_size = {}
  vim.notify("Barline cache cleared")
end

---Get debug information about all components
---@return table<string, {enabled: boolean, output: string, condition?: boolean}> debug_info
function M.debug_info()
  local info = {}
  for name, _ in pairs(components) do
    if M.config[name] then
      local component_config = M.config[name]
      local condition_result = true
      if component_config.condition then
        condition_result = component_config.condition()
      end

      info[name] = {
        enabled = component_config.enabled,
        condition = condition_result,
        output = condition_result and components[name](M.config) or "[condition failed]",
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
---local barline = require("barline")
---
---barline.register_component("time", function(cfg)
---  return barline.with_hl(cfg.time.icon .. cfg.time.prefix .. os.date("%H:%M") .. cfg.time.suffix, cfg.time.hl)
---end, {
---  icon = "",
---  hl = "CurSearch",
---})
---```
function M.register_component(name, fn, default_config)
  -- Wrap function with condition checking
  local wrapped_fn = function(config)
    local component_config = config[name]
    if component_config and component_config.condition and not component_config.condition() then
      return ""
    end
    return fn(config)
  end

  components[name] = wrapped_fn

  if not M.defaults[name] then
    M.defaults[name] = vim.tbl_deep_extend("force", {
      enabled = true,
      prefix = "",
      suffix = "",
      hl = "Barline" .. name:gsub("^%l", string.upper),
    }, default_config or {})
  end
end

---Get current configuration
---@return Barline.Config config Current configuration
function M.get_config()
  return M.config
end

return M
