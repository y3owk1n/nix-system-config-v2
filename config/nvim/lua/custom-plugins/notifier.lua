---@class Notifier
---@field anchor "NW"|"NE"|"SW"|"SE"
---@field row integer
---@field col integer

---@class Notifier.Config
---@field default_timeout? integer
---@field winblend? integer
---@field border? string
---@field group_configs? table<string, Notifier>

---@class Notifier.Notification
---@field id? string|number
---@field msg string
---@field level integer
---@field timeout integer
---@field created_at number
---@field updated_at? number
---@field hl_group? string
---@field _expired? boolean

---@class Notifier.Group
---@field name string
---@field buf integer
---@field win integer
---@field notifications Notifier.Notification[]
---@field conf Notifier

local M = {}

local api = vim.api
local uv = vim.uv or vim.loop

---@type table<string, Notifier.Group>
local groups = {}

---@type Notifier.Config
local config = {
  default_timeout = 3000, -- milliseconds
  winblend = 0,
  border = "none",
  group_configs = {
    default = {
      anchor = "SE", -- South-East
      row = vim.o.lines - 2,
      col = vim.o.columns,
    },
    important = {
      anchor = "SW", -- South-West
      row = vim.o.lines - 2,
      col = 0,
    },
  },
}

---Return an existing group or create a new one.
---@param name string
---@return Notifier.Group
local function get_group(name)
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
    border = config.border,
    row = 0,
    col = 0,
    anchor = "NW",
    zindex = 200,
  })

  local group_conf = config.group_configs[name] or config.group_configs.default
  api.nvim_win_set_config(win, {
    relative = "editor",
    row = group_conf.row,
    col = group_conf.col,
    anchor = group_conf.anchor,
    style = "minimal",
    border = "none",
    width = 1,
    height = 1,
    zindex = 200,
  })

  api.nvim_set_option_value("winblend", config.winblend or 0, { scope = "local", win = win })

  groups[name] = vim.tbl_deep_extend("keep", groups[name] or {}, {
    name = name,
    buf = buf,
    win = win,
    notifications = {},
    conf = group_conf,
  })

  return groups[name]
end

---Render all messages in the group.
---@param group Notifier.Group
local function render_group(group)
  local live = vim.tbl_filter(function(n)
    return not n._expired
  end, group.notifications)

  -- If no notifications, close and cleanup
  if #live == 0 then
    if api.nvim_win_is_valid(group.win) then
      api.nvim_win_close(group.win, true)
    end
    if api.nvim_buf_is_valid(group.buf) then
      api.nvim_buf_delete(group.buf, { force = true })
    end
    return
  end

  ---@type table<integer, { text: string, hl_group?: string }>[]
  local segments = {}

  local separator = { text = " " }

  local hl_groups = {
    [vim.log.levels.ERROR] = "NotifierError",
    [vim.log.levels.WARN] = "NotifierWarn",
    [vim.log.levels.INFO] = "NotifierInfo",
    [vim.log.levels.DEBUG] = "NotifierDebug",
    [vim.log.levels.TRACE] = "NotifierTrace",
  }

  local log_level_map = {
    [vim.log.levels.ERROR] = "ERROR",
    [vim.log.levels.WARN] = "WARN",
    [vim.log.levels.INFO] = "INFO",
    [vim.log.levels.DEBUG] = "DEBUG",
    [vim.log.levels.TRACE] = "TRACE",
  }

  local push_forward_segment_idx = 0

  for i = #live, 1, -1 do
    local notif = live[i]
    local msg = notif.msg
    local level = notif.level
    local hl = notif.hl_group

    local splitted_msg = vim.split(msg, "\n")

    if #splitted_msg > 1 then
      for j = 1, #splitted_msg do
        local segment = {
          { text = splitted_msg[j], hl_group = hl },
          separator,
          { text = string.format("[%s]", log_level_map[level]), hl_group = hl_groups[level] },
        }
        table.insert(segments, segment)
        push_forward_segment_idx = push_forward_segment_idx + 1
      end
    else
      segments[i + push_forward_segment_idx] = {
        { text = msg, hl_group = hl },
        separator,
        { text = string.format("[%s]", log_level_map[level]), hl_group = hl_groups[level] },
      }
    end
  end

  local lines = {}

  for i = 1, #segments do
    local flattened = {}
    local segment = segments[i]
    for j = 1, #segment do
      local item = segment[j]
      table.insert(flattened, item.text)
    end
    lines[i] = table.concat(flattened, "")
  end

  api.nvim_buf_set_lines(group.buf, 0, -1, false, lines)

  vim.bo[group.buf].filetype = "markdown"
  vim.bo[group.buf].syntax = "markdown"
  vim.wo[group.win].conceallevel = 3

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  api.nvim_win_set_config(group.win, {
    relative = "editor",
    row = group.conf.row,
    col = group.conf.col,
    anchor = group.conf.anchor,
    style = "minimal",
    border = "none",
    width = width,
    height = #lines,
    zindex = 200,
  })

  local ns = vim.api.nvim_create_namespace("notifier-notification")
  vim.api.nvim_buf_clear_namespace(group.buf, ns, 0, -1)

  for i = 1, #segments do
    local segment = segments[i]
    local col = 0
    for j = 1, #segment do
      local item = segment[j]
      if item.hl_group then
        vim.api.nvim_buf_set_extmark(group.buf, ns, i - 1, col, {
          end_col = col + #item.text,
          hl_group = item.hl_group,
        })
      end
      col = col + #item.text
    end
  end
end

---Override for vim.notify
---@param msg string
---@param level? integer
---@param opts? {id?: string|number, timeout?: integer, group?: string, hl_group?: string}
function M.notify(msg, level, opts)
  opts = opts or {}
  local id = opts.id
  local timeout = opts.timeout or config.default_timeout
  local hl_group = opts.hl_group
  local group_name = opts.group or "default"
  local group = get_group(group_name)

  local now = os.time()

  -- Replace existing message with same ID
  if id then
    for _, notif in ipairs(group.notifications) do
      if notif.id == id then
        notif.msg = msg
        notif.level = level or vim.log.levels.INFO
        notif.updated_at = now
        notif.hl_group = hl_group
        render_group(group)
        return
      end
    end
  end

  -- Add new message
  table.insert(group.notifications, {
    id = id,
    msg = msg,
    level = level or vim.log.levels.INFO,
    timeout = timeout,
    created_at = now,
    updated_at = nil,
    hl_group = hl_group,
  })

  render_group(group)
end

-- Setup auto-cleanup timer
local function start_cleanup_timer()
  local timer = uv.new_timer()
  if timer then
    timer:start(
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
            render_group(group)
          end
        end
      end)
    )
  end
end

---Show every notification that is currently alive in any group.
function M.show_history()
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  -- Collect everything that is still in groups
  ---@type Notifier.Notification[]
  local all = {}
  for _, g in pairs(groups) do
    for _, n in ipairs(g.notifications) do
      table.insert(all, n)
    end
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
  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = "Active Notifications",
    title_pos = "center",
  })

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true

  local close = function()
    if api.nvim_win_is_valid(win) then
      api.nvim_win_close(win, true)
    end
  end
  for _, key in ipairs({ "<Esc>", "q", "<C-c>" }) do
    vim.keymap.set("n", key, close, { buffer = buf, nowait = true })
  end

  ---@type table<integer, { text: string, hl_group?: string }>[]
  local segments = {}

  local separator = { text = " " }

  local hl_groups = {
    [vim.log.levels.ERROR] = "NotifierError",
    [vim.log.levels.WARN] = "NotifierWarn",
    [vim.log.levels.INFO] = "NotifierInfo",
    [vim.log.levels.DEBUG] = "NotifierDebug",
    [vim.log.levels.TRACE] = "NotifierTrace",
  }

  local log_level_map = {
    [vim.log.levels.ERROR] = "ERROR",
    [vim.log.levels.WARN] = "WARN",
    [vim.log.levels.INFO] = "INFO",
    [vim.log.levels.DEBUG] = "DEBUG",
    [vim.log.levels.TRACE] = "TRACE",
  }

  local push_forward_segment_idx = 0

  for i = #all, 1, -1 do
    local notif = all[i]
    local msg = notif.msg
    local level = notif.level
    local hl = notif.hl_group

    local splitted_msg = vim.split(msg, "\n")

    local pretty_time = os.date("%Y-%m-%d %H:%M:%S", notif.updated_at or notif.created_at)

    if #splitted_msg > 1 then
      for j = 1, #splitted_msg do
        local segment = {
          {
            text = pretty_time,
            hl_group = "Comment",
          },
          separator,
          { text = splitted_msg[j], hl_group = hl },
          separator,
          { text = string.format("[%s]", log_level_map[level]), hl_group = hl_groups[level] },
        }
        table.insert(segments, segment)
        push_forward_segment_idx = push_forward_segment_idx + 1
      end
    else
      segments[i + push_forward_segment_idx] = {
        {
          text = pretty_time,
          hl_group = "Comment",
        },
        separator,
        { text = msg, hl_group = hl },
        separator,
        { text = string.format("[%s]", log_level_map[level]), hl_group = hl_groups[level] },
      }
    end
  end

  -- Build lines
  local lines = {}
  for i = 1, #segments do
    local flattened = {}
    local segment = segments[i]
    for j = 1, #segment do
      local item = segment[j]
      table.insert(flattened, item.text)
    end
    lines[i] = table.concat(flattened, "")
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].syntax = "markdown"
  vim.wo[win].conceallevel = 3

  local ns = vim.api.nvim_create_namespace("notifier-history")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  for i = 1, #segments do
    local segment = segments[i]
    local col = 0
    for j = 1, #segment do
      local item = segment[j]
      if item.hl_group then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, col, {
          end_col = col + #item.text,
          hl_group = item.hl_group,
        })
      end
      col = col + #item.text
    end
  end
end

---Immediately dismiss every active notification and close their windows.
function M.dismiss_all()
  for _, group in pairs(groups) do
    if api.nvim_win_is_valid(group.win) then
      api.nvim_win_close(group.win, true)
    end
    if api.nvim_buf_is_valid(group.buf) then
      api.nvim_buf_delete(group.buf, { force = true })
    end
  end
end

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
function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})

  setup_hls()

  -- Override vim.notify
  vim.notify = M.notify

  -- Start cleanup
  start_cleanup_timer()
end

return M
