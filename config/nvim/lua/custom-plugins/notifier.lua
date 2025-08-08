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
---@field msg string The message to display and can contain newlines or just "" if you want to use the `_notif_formatter` to build the lines.
---@field icon? string
---@field level integer
---@field timeout integer
---@field created_at number
---@field updated_at? number
---@field hl_group? string
---@field _expired? boolean
---@field _notif_formatter? fun(notif: Notifier.Notification, line: string, config: Notifier.Config, log_level_map: Notifier.LogLevelMap, _notif_formatter_data?: table): Notifier.FormattedNotifOpts[]
---@field _notif_formatter_data? table

---@class Notifier
local Notifier = {}

---@class Notifier.Helpers
local H = {}

---@class Notifier.UI
local U = {}

local api = vim.api

------------------------------------------------------------------
-- Constants & Setup
------------------------------------------------------------------

---@class Notifier.Group
---@field name string
---@field buf integer
---@field win integer
---@field notifications Notifier.Notification[]
---@field config Notifier.Config.GroupConfigs

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

  local group_config = Notifier.config.group_configs[name] or Notifier.config.group_configs.default

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
---@field text string The display text
---@field hl_group? string The highlight group of the text

---@param notif Notifier.Notification
---@param line string
---@param config Notifier.Config
---@param _log_level_map Notifier.LogLevelMap
---@param _notif_formatter_data? table -- user defined data
---@return Notifier.FormattedNotifOpts[]
function U.notif_formatter(notif, line, config, _log_level_map, _notif_formatter_data)
  local separator = { text = " " }

  local icon = notif.icon or config.icons[notif.level]
  local icon_hl = notif.hl_group or _log_level_map[notif.level].hl_group

  return {
    icon and { text = icon, hl_group = icon_hl },
    icon and separator,
    { text = line, hl_group = notif.hl_group },
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

  ---@type table<integer, Notifier.FormattedNotifOpts>[]
  local segments = {}

  for i = #live, 1, -1 do
    local notif = live[i]

    if notif._notif_formatter and type(notif._notif_formatter) == "function" then
      local formatted = notif._notif_formatter(notif, "", Notifier.config, log_level_map, notif._notif_formatter_data)
      table.insert(segments, formatted)
      notif.msg = table.concat(
        vim.tbl_map(function(s)
          return s.text
        end, formatted),
        ""
      )
      goto continue
    end

    local msg_lines = vim.split(notif.msg, "\n")
    for _, line in ipairs(msg_lines) do
      table.insert(
        segments,
        Notifier.config.notif_formatter(notif, line, Notifier.config, log_level_map, notif._notif_formatter_data)
      )
    end
    ::continue::
  end

  local lines = {}

  for _, seg in pairs(segments) do
    table.insert(
      lines,
      table.concat(vim.tbl_map(function(s)
        return s.text
      end, seg))
    )
  end

  pcall(api.nvim_buf_set_lines, group.buf, 0, -1, false, lines)

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
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

  local ns = vim.api.nvim_create_namespace("notifier-notification")
  vim.api.nvim_buf_clear_namespace(group.buf, ns, 0, -1)

  for lnum, seg in ipairs(segments) do
    local col = 0
    for _, item in ipairs(seg) do
      if item.hl_group then
        api.nvim_buf_set_extmark(group.buf, ns, lnum - 1, col, {
          end_col = col + #item.text,
          hl_group = item.hl_group,
        })
      end
      col = col + #item.text
    end
  end
end

------------------------------------------------------------------
-- Public Interface
------------------------------------------------------------------

---Override for vim.notify
---@param msg string
---@param level? integer
---@param opts? {id?: string|number, timeout?: integer, group?: string, hl_group?: string, icon?: string, _notif_formatter_data?: table, _notif_formatter?: fun(notif: Notifier.Notification, line: string, config: Notifier.Config, log_level_map: Notifier.LogLevelMap, _notif_formatter_data: table): Notifier.FormattedNotifOpts[]}
function Notifier.notify(msg, level, opts)
  opts = opts or {}
  local id = opts.id
  local timeout = opts.timeout or Notifier.config.default_timeout
  local hl_group = opts.hl_group
  local group_name = opts.group or "default"
  local icon = opts.icon
  local group = H.get_group(group_name)
  local now = os.time()
  local _notif_formatter = opts._notif_formatter
  local _notif_formatter_data = opts._notif_formatter_data

  -- Replace existing message with same ID
  if id then
    for index, notif in ipairs(group.notifications) do
      if notif.id == id then
        notif.msg = msg
        notif.level = level or vim.log.levels.INFO
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

  ---@type table<integer, Notifier.FormattedNotifOpts>[]
  local segments = {}

  local separator = { text = " " }

  for i = #all, 1, -1 do
    local notif = all[i]
    local msg = notif.msg
    local level = notif.level
    local hl = notif.hl_group

    local splitted_msg = vim.split(msg, "\n")

    local pretty_time = os.date("%Y-%m-%d %H:%M:%S", notif.updated_at or notif.created_at)

    for _, line in ipairs(splitted_msg) do
      table.insert(segments, {
        {
          text = pretty_time,
          hl_group = "Comment",
        },
        separator,
        { text = line, hl_group = hl },
        separator,
        {
          text = string.format("[%s]", log_level_map[level].level_key),
          hl_group = log_level_map[level].hl_group,
        },
      })
    end
  end

  -- Build lines
  local lines = {}
  for _, seg in ipairs(segments) do
    table.insert(
      lines,
      table.concat(vim.tbl_map(function(s)
        return s.text
      end, seg))
    )
  end

  pcall(api.nvim_buf_set_lines, buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false
  local ns = vim.api.nvim_create_namespace("notifier-history")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for lnum, seg in ipairs(segments) do
    local col = 0
    for _, item in ipairs(seg) do
      if item.hl_group then
        api.nvim_buf_set_extmark(buf, ns, lnum - 1, col, {
          end_col = col + #item.text,
          hl_group = item.hl_group,
        })
      end
      col = col + #item.text
    end
  end

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

---@class Notifier.Config
---@field default_timeout? integer
---@field winblend? integer
---@field border? string
---@field group_configs? table<string, Notifier.Config.GroupConfigs>
---@field icons? table<string, string>
---@field notif_formatter? fun(notif: Notifier.Notification, line: string, config: Notifier.Config, log_level_map: Notifier.LogLevelMap, _notif_formatter_data?: table): Notifier.FormattedNotifOpts[]

---@class Notifier.Config.GroupConfigs
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
  group_configs = {
    default = {
      anchor = "SE", -- South-East
      row = vim.o.lines - 2,
      col = vim.o.columns,
    },
  },
  icons = {
    [vim.log.levels.TRACE] = "󰔚 ",
    [vim.log.levels.DEBUG] = " ",
    [vim.log.levels.INFO] = " ",
    [vim.log.levels.WARN] = " ",
    [vim.log.levels.ERROR] = " ",
  },
  notif_formatter = U.notif_formatter,
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

  setup_hls()

  vim.notify = Notifier.notify

  start_cleanup_timer()
end

return Notifier
