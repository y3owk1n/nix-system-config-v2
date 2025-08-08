local ok, uv = pcall(function()
  return vim.uv or vim.loop
end)

if not ok or uv == nil then
  error("notifier.nvim: libuv not available")
end

local nvim = vim.version()
if nvim.major == 0 and (nvim.minor < 10 or (nvim.minor == 10 and nvim.patch < 0)) then
  vim.notify("notifier.nvim requires Neovim 0.10+", vim.log.levels.ERROR)
  return
end

---@class Notifier.Notification
---@field id? string|number
---@field msg? string The message to display and can contain newlines or just "" if you want to use the `_notif_formatter` to build the lines.
---@field icon? string
---@field level? integer
---@field timeout? integer
---@field created_at? number
---@field updated_at? number
---@field hl_group? string
---@field _expired? boolean
---@field _notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[]
---@field _notif_formatter_data? table

---@class Notifier.NotificationGroup : Notifier.Notification
---@field group_name? Notifier.GroupConfigsKey

---@class Notifier
local Notifier = {}

---@class Notifier.Helpers
local H = {}

---@class Notifier.UI
local U = {}

---@class Notifier.Validator
local V = {}

local api = vim.api

------------------------------------------------------------------
-- Constants & Setup
------------------------------------------------------------------

---@class Notifier.Group
---@field name string
---@field buf integer
---@field win integer
---@field notifications Notifier.Notification[]
---@field config Notifier.GroupConfigs

---@type table<string, Notifier.Group>
local groups = {}

---@alias Notifier.LogLevelMap table<integer, {level_key: "ERROR"|"WARN"|"INFO"|"DEBUG"|"TRACE", hl_group: string}>
---@type Notifier.LogLevelMap
local log_level_map = {
  [vim.log.levels.ERROR] = {
    level_key = "ERROR",
    hl_group = "NotifierError",
  },
  [vim.log.levels.WARN] = {
    level_key = "WARN",
    hl_group = "NotifierWarn",
  },
  [vim.log.levels.INFO] = {
    level_key = "INFO",
    hl_group = "NotifierInfo",
  },
  [vim.log.levels.DEBUG] = {
    level_key = "DEBUG",
    hl_group = "NotifierDebug",
  },
  [vim.log.levels.TRACE] = {
    level_key = "TRACE",
    hl_group = "NotifierTrace",
  },
}

------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------

-- Resolve effective padding: group > global > zero
---@return Notifier.Config.Padding
function H.resolve_padding()
  local c = Notifier.config.padding
  return {
    top = (c and c.top) or 0,
    right = (c and c.right) or 0,
    bottom = (c and c.bottom) or 0,
    left = (c and c.left) or 0,
  }
end

---Return an existing group or create a new one.
---@param name string
---@return Notifier.Group
function H.get_group(name)
  if groups[name] then
    local buf_valid = api.nvim_buf_is_valid(groups[name].buf)
    local win_valid = api.nvim_win_is_valid(groups[name].win)

    if buf_valid and win_valid then
      return groups[name]
    end

    groups[name].buf = nil
    groups[name].win = nil
  end

  local buf = api.nvim_create_buf(false, true)

  local win = api.nvim_open_win(buf, false, {
    relative = "editor",
    width = 1,
    height = 1,
    focusable = false,
    style = "minimal",
    border = Notifier.config.border,
    row = 0,
    col = 0,
    anchor = "NW",
    zindex = 200,
  })

  local group_config = Notifier.config.group_configs[name]
    or Notifier.config.group_configs[Notifier.config.default_group]

  api.nvim_win_set_config(win, {
    relative = "editor",
    row = group_config.row,
    col = group_config.col,
    anchor = group_config.anchor,
    width = 1,
    height = 1,
  })

  api.nvim_set_option_value("winblend", Notifier.config.winblend or 0, { scope = "local", win = win })

  groups[name] = vim.tbl_deep_extend("keep", groups[name] or {}, {
    name = name,
    buf = buf,
    win = win,
    notifications = {},
    config = group_config,
  })

  return groups[name]
end

---Parse a format result and ensure all in string
---@param format_result Notifier.FormattedNotifOpts[] The format result
---@param ignore_padding? boolean ignore the padding
---@return Notifier.ComputedLineOpts[] lines raw The parsed format result
function H.parse_format_fn_result(format_result, ignore_padding)
  ignore_padding = ignore_padding or false
  local pad = H.resolve_padding()

  ---@type Notifier.ComputedLineOpts[]
  local parsed = {}

  ---@type number keep track of the col counts to proper compute every col position
  local current_line_col = 0

  ---Temp table to add padding start and end
  ---@type Notifier.ComputedLineOpts[]
  local prepare_lines = {}

  -- add padding start
  if not ignore_padding and pad.left then
    table.insert(prepare_lines, {
      display_text = string.rep(" ", pad.left),
    })
  end

  for _, item in ipairs(format_result) do
    table.insert(prepare_lines, item)
  end

  if not ignore_padding and pad.right then
    -- add padding end
    table.insert(prepare_lines, {
      display_text = string.rep(" ", pad.right),
    })
  end

  for _, item in ipairs(prepare_lines) do
    if type(item) ~= "table" then
      goto continue
    end

    ---@type Notifier.ComputedLineOpts
    ---@diagnostic disable-next-line: missing-fields
    local parsed_item = {}

    -- force `is_virtual` to false just in case
    parsed_item.is_virtual = item.is_virtual or false

    if item.display_text then
      if type(item.display_text) == "string" then
        parsed_item.display_text = item.display_text
      end

      -- just in case user did not `tostring` the number
      if type(item.display_text) == "number" then
        parsed_item.display_text = tostring(item.display_text)
      end

      if not parsed_item.is_virtual then
        ---calculate the start and end column one by one
        parsed_item.col_start = current_line_col
        current_line_col = parsed_item.col_start + #parsed_item.display_text
        parsed_item.col_end = current_line_col
      else
        parsed_item.col_start = current_line_col
      end
    end

    if item.hl_group then
      if type(item.hl_group) == "string" then
        parsed_item.hl_group = item.hl_group
      end
    end

    table.insert(parsed, parsed_item)

    ::continue::
  end

  return parsed
end

---Convert a parsed format result to string
---@param parsed Notifier.ComputedLineOpts[] The parsed format result
---@return string lines The formatted lines
function H.convert_parsed_format_result_to_string(parsed)
  local display_lines = {}

  for _, item in ipairs(parsed) do
    if item.display_text and not item.is_virtual then
      table.insert(display_lines, item.display_text)
    end
  end

  return table.concat(display_lines, "")
end

---Set the highlight for the list items
---@param ns number The namespace
---@param bufnr number The buffer number
---@param line_data Notifier.ComputedLineOpts[][] The formatted line data
---@return nil
function H.set_list_item_hl_fn(ns, bufnr, line_data)
  api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for line_number, line in ipairs(line_data) do
    if not line or line == "" then
      goto continue
    end
    for _, data in ipairs(line) do
      if data.is_virtual then
        -- set the virtual text in the right position with it's hl group
        api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, data.col_start, {
          virt_text = { { data.display_text, data.hl_group } },
          virt_text_pos = "inline",
        })
      else
        if data.col_start and data.col_end then
          api.nvim_buf_set_extmark(bufnr, ns, line_number - 1, data.col_start, {
            end_col = data.col_end,
            hl_group = data.hl_group,
          })
        end
      end
    end
    ::continue::
  end
end

------------------------------------------------------------------
-- UI
------------------------------------------------------------------

---@type uv.uv_timer_t?
local render_timer = assert(uv.new_timer(), "uv_timer_t")

---@type boolean
local dirty = false

function U.debounce_render()
  dirty = true
  if not render_timer then
    return
  end
  render_timer:stop()
  render_timer:start(
    50,
    0,
    vim.schedule_wrap(function()
      if not dirty then
        return
      end
      dirty = false
      for _, g in pairs(groups) do
        U.render_group(g)
      end
    end)
  )
end

---@class Notifier.FormattedNotifOpts
---@field display_text string The display text
---@field hl_group? string The highlight group of the text
---@field is_virtual? boolean Whether the line is virtual

---@class Notifier.ComputedLineOpts : Notifier.FormattedNotifOpts
---@field col_start? number The start column of the text, NOTE: this is calculated and for type purpose only
---@field col_end? number The end column of the text, NOTE: this is calculated and for type purpose only

---@class Notifier.NotificationFormatterOpts
---@field notif Notifier.Notification
---@field line string
---@field config Notifier.Config
---@field log_level_map Notifier.LogLevelMap

---@param opts Notifier.NotificationFormatterOpts
---@return Notifier.FormattedNotifOpts[]
function U.default_notif_formatter(opts)
  local notif = opts.notif
  local line = opts.line
  local config = opts.config
  local _log_level_map = opts.log_level_map

  local separator = { display_text = " " }

  local icon = notif.icon or config.icons[notif.level]
  local icon_hl = notif.hl_group or _log_level_map[notif.level].hl_group

  return {
    icon and { display_text = icon, hl_group = icon_hl },
    icon and separator,
    { display_text = line, hl_group = notif.hl_group },
  }
end

---@param opts Notifier.NotificationFormatterOpts
---@return Notifier.FormattedNotifOpts[]
function U.default_notif_history_formatter(opts)
  local virtual_separator = { display_text = " ", is_virtual = true }

  local line = opts.line

  local notif = opts.notif
  local hl = notif.hl_group

  local pretty_time = os.date("%Y-%m-%d %H:%M:%S", notif.updated_at or notif.created_at)

  return {
    {
      display_text = pretty_time,
      hl_group = "Comment",
      is_virtual = true,
    },
    virtual_separator,
    {
      display_text = string.format("[%s]", log_level_map[notif.level].level_key),
      hl_group = log_level_map[notif.level].hl_group,
      is_virtual = true,
    },
    virtual_separator,
    { display_text = line, hl_group = hl },
  }
end

---Render all messages in the group.
---@param group Notifier.Group
function U.render_group(group)
  ---@type Notifier.Notification[]
  local live = vim.tbl_filter(function(n)
    return not n._expired
  end, group.notifications)

  -- If no notifications, close and cleanup
  if #live == 0 then
    pcall(api.nvim_win_close, group.win, true)
    pcall(api.nvim_buf_delete, group.buf, { force = true })
    return
  end

  ---@type string[]
  local lines = {}

  ---@type Notifier.FormattedNotifOpts[][]
  local formatted_raw_data = {}

  for i = #live, 1, -1 do
    local notif = live[i]

    if notif._notif_formatter and type(notif._notif_formatter) == "function" and notif.msg == "" then
      local formatted =
        notif._notif_formatter({ notif = notif, line = "", config = Notifier.config, log_level_map = log_level_map })

      local formatted_line_data = H.parse_format_fn_result(formatted)

      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
      goto continue
    end

    local msg_lines = vim.split(notif.msg, "\n")

    for _, line in ipairs(msg_lines) do
      local formatted = Notifier.config.notif_formatter({
        notif = notif,
        line = line,
        config = Notifier.config,
        log_level_map = log_level_map,
      })

      local formatted_line_data = H.parse_format_fn_result(formatted)

      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
    end
    ::continue::
  end

  local pad = H.resolve_padding()

  for _ = 1, pad.top do
    --- insert emtpy line into first position to `lines` table
    table.insert(lines, 1, "")
    table.insert(formatted_raw_data, 1, "")
  end

  for _ = 1, pad.bottom do
    table.insert(lines, #lines + 1, "")
    table.insert(formatted_raw_data, #formatted_raw_data + 1, "")
  end

  pcall(api.nvim_buf_set_lines, group.buf, 0, -1, false, lines)

  local ns = vim.api.nvim_create_namespace("notifier-notification")
  H.set_list_item_hl_fn(ns, group.buf, formatted_raw_data)

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line), 40)
  end

  width = math.min(width, math.floor(vim.o.columns * 0.6))
  local height = #lines

  local ok_win, _ = pcall(api.nvim_win_set_config, group.win, {
    relative = "editor",
    row = group.config.row,
    col = group.config.col,
    anchor = group.config.anchor,
    width = width,
    height = height,
  })

  if not ok_win then
    return
  end
end

------------------------------------------------------------------
-- Validator
------------------------------------------------------------------

---Validate a log level number and clamp to valid range.
---@param level any
---@return integer
function V.validate_level(level)
  if type(level) ~= "number" then
    return vim.log.levels.INFO
  end

  -- Clamp to nearest valid level
  local min_level, max_level = vim.log.levels.TRACE, vim.log.levels.ERROR
  if level < min_level then
    return min_level
  elseif level > max_level then
    return max_level
  end

  return level
end

---Validate a message, ensuring it's a string.
---@param msg any
---@return string
function V.validate_msg(msg)
  if type(msg) ~= "string" then
    return tostring(msg or "")
  end
  return msg
end

---Validate padding table, ensuring numeric and non-negative.
---@param padding any
---@return Notifier.Config.Padding
function V.validate_padding(padding)
  local function safe_num(v)
    return (type(v) == "number" and v >= 0) and v or 0
  end
  if type(padding) ~= "table" then
    return { top = 0, right = 0, bottom = 0, left = 0 }
  end
  return {
    top = safe_num(padding.top),
    right = safe_num(padding.right),
    bottom = safe_num(padding.bottom),
    left = safe_num(padding.left),
  }
end

---Validate anchor value for floating windows.
---@param anchor any
---@return "NW"|"NE"|"SW"|"SE"
function V.validate_anchor(anchor)
  local valid = { NW = true, NE = true, SW = true, SE = true }
  if type(anchor) == "string" and valid[anchor] then
    return anchor
  end
  return "SE"
end

function V.validate_row_col(row_col)
  if type(row_col) == "number" and row_col >= 0 then
    return row_col
  end
  return 0
end

---Validate timeout, ensuring it’s positive ms.
---@param timeout any
---@return integer
function V.validate_timeout(timeout)
  if type(timeout) ~= "number" or timeout < 0 then
    return Notifier.config.default_timeout or Notifier.defaults.default_timeout or 3000
  end
  return timeout
end

---Validate a formatter function.
---@param formatter any
---@return fun(opts:Notifier.NotificationFormatterOpts):Notifier.FormattedNotifOpts[]
function V.validate_formatter(formatter)
  if type(formatter) == "function" then
    return formatter
  end
  return Notifier.defaults.notif_formatter
end

---Validate icon string (optional).
---@param icon any
---@return string|nil
function V.validate_icon(icon)
  if type(icon) == "string" then
    return icon
  end
  return nil
end

---Validate highlight group name.
---@param hl any
---@return string|nil
function V.validate_hl(hl)
  if type(hl) == "string" and #hl > 0 then
    return hl
  end
  return nil
end

---Validate group name to be a non-empty string.
---@param name any
---@return Notifier.GroupConfigsKey
function V.validate_group_name(name)
  if type(name) ~= "string" then
    return Notifier.defaults.default_group
  end

  local valid_groups = vim.tbl_keys(Notifier.config.group_configs)
  if not vim.tbl_contains(valid_groups, name) then
    return Notifier.defaults.default_group
  end

  return name
end

---@param group_configs table<Notifier.GroupConfigsKey, Notifier.GroupConfigs>
function V.validate_group_configs(group_configs)
  if type(group_configs) ~= "table" then
    return Notifier.defaults.group_configs
  end

  local valid_groups = vim.tbl_keys(Notifier.defaults.group_configs)
  for group_name, _ in pairs(group_configs) do
    if not vim.tbl_contains(valid_groups, group_name) then
      return Notifier.defaults.group_configs
    end
  end

  return group_configs
end

------------------------------------------------------------------
-- Public Interface
------------------------------------------------------------------

---Override for vim.notify
---@param msg string
---@param level? integer
---@param opts? Notifier.NotificationGroup
function Notifier.notify(msg, level, opts)
  opts = opts or {}
  local id = opts.id
  local timeout = V.validate_timeout(opts.timeout)
  local hl_group = V.validate_hl(opts.hl_group)
  local group_name = V.validate_group_name(opts.group_name)
  local icon = V.validate_icon(opts.icon)
  local group = H.get_group(group_name)
  local now = os.time()
  local _notif_formatter = V.validate_formatter(opts._notif_formatter)
  local _notif_formatter_data = type(opts._notif_formatter_data) == "table" and opts._notif_formatter_data or nil
  level = V.validate_level(level)
  msg = V.validate_msg(msg)

  -- Replace existing message with same ID
  if id then
    for _, notif in ipairs(group.notifications) do
      if notif.id == id then
        notif.msg = msg
        notif.level = level or vim.log.levels.INFO
        notif.timeout = timeout
        notif.icon = icon
        notif.updated_at = now
        notif.hl_group = hl_group
        notif._notif_formatter = _notif_formatter
        notif._notif_formatter_data = _notif_formatter_data
        U.debounce_render()
        return
      end
    end
  end

  -- Add new message
  table.insert(group.notifications, {
    id = id,
    msg = msg,
    icon = icon,
    level = level or vim.log.levels.INFO,
    timeout = timeout,
    created_at = now,
    updated_at = nil,
    hl_group = hl_group,
    _notif_formatter = _notif_formatter,
    _notif_formatter_data = _notif_formatter_data,
  })

  U.debounce_render()
end

---@type uv.uv_timer_t?
local cleanup_timer = nil

-- Setup auto-cleanup timer
local function start_cleanup_timer()
  if cleanup_timer and not cleanup_timer:is_closing() then
    cleanup_timer:stop()
    cleanup_timer:close()
  end

  cleanup_timer = assert(uv.new_timer(), "uv_timer_t")

  if not cleanup_timer then
    return
  end

  cleanup_timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      local now = os.time() * 1000

      for _, group in pairs(groups) do
        local changed = false
        for i = #group.notifications, 1, -1 do
          local notif = group.notifications[i]

          if notif._expired then
            goto continue
          end

          local elapsed_ms = (now - ((notif.updated_at or notif.created_at) * 1000))
          if elapsed_ms >= notif.timeout then
            notif._expired = true
            changed = true
          end
          ::continue::
        end
        if changed then
          U.debounce_render()
        end
      end
    end)
  )
end

---Show every notification that is currently alive in any group.
function Notifier.show_history()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  -- Collect everything that is still in groups
  ---@type Notifier.Notification[]
  local all = {}

  for _, g in pairs(groups) do
    vim.list_extend(all, g.notifications)
  end

  if #all == 0 then
    vim.notify("No active notifications", vim.log.levels.INFO)
    return
  end

  -- sort oldest → newest
  table.sort(all, function(a, b)
    return a.created_at < b.created_at
  end)

  -- Prepare floating window / buffer
  local buf = api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = "Notification History",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true

  local close = function()
    pcall(api.nvim_win_close, win, true)
  end

  for _, key in ipairs({ "<Esc>", "q", "<C-c>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end

  api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })

  ---@type string[]
  local lines = {}

  ---@type Notifier.FormattedNotifOpts[][]
  local formatted_raw_data = {}

  for i = #all, 1, -1 do
    local notif = all[i]

    if notif._notif_formatter and type(notif._notif_formatter) == "function" and notif.msg == "" then
      local formatted =
        notif._notif_formatter({ notif = notif, line = "", config = Notifier.config, log_level_map = log_level_map })

      local formatted_line_data = H.parse_format_fn_result(formatted, true)

      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      -- build the message and save it
      notif.msg = formatted_line
    end

    local msg_lines = vim.split(notif.msg, "\n")

    for _, line in ipairs(msg_lines) do
      local formatted = Notifier.config.notif_history_formatter({
        notif = notif,
        line = line,
        config = Notifier.config,
        log_level_map = log_level_map,
      })

      local formatted_line_data = H.parse_format_fn_result(formatted, true)
      local formatted_line = H.convert_parsed_format_result_to_string(formatted_line_data)

      table.insert(lines, formatted_line)
      table.insert(formatted_raw_data, formatted_line_data)
    end
  end

  pcall(api.nvim_buf_set_lines, buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false

  local ns = vim.api.nvim_create_namespace("notifier-history")
  H.set_list_item_hl_fn(ns, buf, formatted_raw_data)

  api.nvim_set_current_win(win)
end

---Immediately dismiss every active notification and close their windows.
function Notifier.dismiss_all()
  for _, group in pairs(groups) do
    if api.nvim_win_is_valid(group.win) then
      api.nvim_win_close(group.win, true)
    end
    if api.nvim_buf_is_valid(group.buf) then
      api.nvim_buf_delete(group.buf, { force = true })
    end
  end
end

---@alias Notifier.GroupConfigsKey '"bottom-right"'|'"top-right"'|'"top-left"'|'"bottom-left"'

---@class Notifier.Config
---@field default_timeout? integer
---@field winblend? integer
---@field border? string
---@field icons? table<string, string>
---@field notif_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[]
---@field notif_history_formatter? fun(opts: Notifier.NotificationFormatterOpts): Notifier.FormattedNotifOpts[]
---@field padding? Notifier.Config.Padding
---@field default_group? Notifier.GroupConfigsKey
---@field group_configs? table<Notifier.GroupConfigsKey, Notifier.GroupConfigs>

---@class Notifier.Config.Padding
---@field top? integer
---@field right? integer
---@field bottom? integer
---@field left? integer

---@class Notifier.GroupConfigs
---@field anchor "NW"|"NE"|"SW"|"SE"
---@field row integer
---@field col integer

---@type Notifier.Config
Notifier.config = {}

---@type Notifier.Config
Notifier.defaults = {
  default_timeout = 3000, -- milliseconds
  winblend = 0,
  border = "none",
  padding = { top = 0, right = 0, bottom = 0, left = 0 },
  default_group = "bottom-right",
  group_configs = {
    ["bottom-right"] = {
      anchor = "SE",
      row = vim.o.lines - 2,
      col = vim.o.columns,
    },
    ["top-right"] = {
      anchor = "NE",
      row = 0,
      col = vim.o.columns,
    },
    ["top-left"] = {
      anchor = "NW",
      row = 0,
      col = 0,
    },
    ["bottom-left"] = {
      anchor = "SW",
      row = vim.o.lines - 2,
      col = 0,
    },
  },
  icons = {
    [vim.log.levels.TRACE] = "󰔚 ",
    [vim.log.levels.DEBUG] = " ",
    [vim.log.levels.INFO] = " ",
    [vim.log.levels.WARN] = " ",
    [vim.log.levels.ERROR] = " ",
  },
  notif_formatter = U.default_notif_formatter,
  notif_history_formatter = U.default_notif_history_formatter,
}

---Setup the default highlight groups.
local function setup_hls()
  local hi = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end

  hi("NotifierError", { link = "ErrorMsg" })
  hi("NotifierWarn", { link = "WarningMsg" })
  hi("NotifierInfo", { link = "MoreMsg" })
  hi("NotifierDebug", { link = "Debug" })
  hi("NotifierTrace", { link = "Comment" })
end

---Setup the notifier plugin.
---@param user_config? Notifier.Config
function Notifier.setup(user_config)
  Notifier.config = vim.tbl_deep_extend("force", Notifier.defaults, user_config or {})

  Notifier.config.padding = V.validate_padding(Notifier.config.padding)

  Notifier.config.group_configs = V.validate_group_configs(Notifier.config.group_configs)

  for _, group_config in pairs(Notifier.config.group_configs or {}) do
    group_config.anchor = V.validate_anchor(group_config.anchor)
    group_config.row = V.validate_row_col(group_config.row)
    group_config.col = V.validate_row_col(group_config.col)
  end

  Notifier.config.default_group = V.validate_group_name(Notifier.config.default_group)

  setup_hls()

  vim.notify = Notifier.notify

  start_cleanup_timer()
end

return Notifier
