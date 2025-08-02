local uv = vim.uv or vim.loop

---@class Cmd
local M = {}

------------------------------------------------------------------
-- Constants & Setup
------------------------------------------------------------------

---@type string
local cwd = vim.fn.expand("%:p:h")
if not uv.fs_stat(cwd .. "/.git") then
  cwd = vim.fn.getcwd()
end

---@type string[]
local last_cmd = {}

---@type string[]
local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@type integer
local spinner_idx = 1

---@type integer
local last_spinner = vim.uv.hrtime()

---@class Cmd.Progress
---@field id integer?
---@field timer uv.uv_timer_t?
---@field active boolean
local cmd_progress = {
  id = nil,
  timer = nil,
  active = false,
}

------------------------------------------------------------------
-- Type Aliases
------------------------------------------------------------------

---@alias Cmd.LogLevel "INFO"|"WARN"|"ERROR"

---@class Cmd.RunResult
---@field code integer
---@field out string
---@field err string

------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------

---Display a notification.
---@param msg string
---@param lvl Cmd.LogLevel
---@return nil
local function notify(msg, lvl)
  vim.notify(msg, vim.log.levels[lvl:upper()], { title = "cmd" })
end

---Stream chunks to a string.
---@param chunks string[]
---@return string
local function stream_tostring(chunks)
  return (table.concat(chunks):gsub("\r", "\n"))
end

---Start reading a stream into a buffer.
---@param pipe uv.uv_stream_t
---@param buffer string[]
---@return nil
local function read_stream(pipe, buffer)
  uv.read_start(pipe, function(err, chunk)
    if err then
      return
    end
    if chunk then
      buffer[#buffer + 1] = chunk
    end
  end)
end

---Trim empty lines from a string array.
---@param lines string[]
---@return string[]
local function trim_empty_lines(lines)
  return vim.tbl_filter(function(s)
    return s ~= ""
  end, lines)
end

local function refresh_ui()
  vim.cmd("redraw!")
  vim.cmd("checktime")
end

---Get the environment variables for a command.
---@param executable string
---@return string[]|nil
local function get_cmd_env(executable)
  local env = M.config.env or {}

  ---@type string[]
  local found = {}

  if not vim.tbl_isempty(env) then
    for k, v in pairs(env) do
      if k == executable then
        for _, v2 in ipairs(v) do
          table.insert(found, v2)
        end
      end
    end
  end

  if #found == 0 then
    return nil
  end

  return found
end

------------------------------------------------------------------
-- Spinners
------------------------------------------------------------------

---Start a spinner.
---@param title string
---@param msg string
---@return nil
local function start_cmd_spinner(title, msg)
  if cmd_progress.active then
    return
  end

  cmd_progress.active = true
  cmd_progress.timer = uv.new_timer()
  cmd_progress.id = (cmd_progress.id or 0) + 1

  cmd_progress.timer:start(0, 100, function()
    vim.schedule(function()
      local now = vim.uv.hrtime()
      if now - last_spinner > 80e6 then
        spinner_idx = (spinner_idx % #spinner_chars) + 1
        last_spinner = now
      end

      local icon = spinner_chars[spinner_idx]

      vim.notify(msg, vim.log.levels.INFO, {
        id = "cmd_progress_" .. cmd_progress.id,
        title = title,
        icon = icon,
      })
    end)
  end)
end

---Stop a spinner.
---@param success boolean
---@return nil
local function stop_cmd_spinner(success)
  if not cmd_progress.active then
    return
  end

  cmd_progress.timer:stop()
  cmd_progress.timer:close()
  cmd_progress.active = false

  local icon = success and " " or " "
  local msg = success and "Command completed" or "Command failed"

  vim.schedule(function()
    vim.notify(msg, success and vim.log.levels.INFO or vim.log.levels.ERROR, {
      id = "cmd_progress_" .. cmd_progress.id,
      title = "cmd",
      icon = icon,
    })
  end)
end

------------------------------------------------------------------
-- UI Helpers
------------------------------------------------------------------

---Show output in a scratch buffer (readonly, vsplit).
---@param lines string[]
---@param title string
local function show_buffer(lines, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "cmd"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].buflisted = false
  vim.api.nvim_buf_set_name(buf, title)
  vim.cmd("vsplit | buffer " .. buf)
end

---Show output in a terminal buffer.
---@param cmd string[]
---@param title string
local function show_terminal(cmd, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "cmd"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.keymap.set("n", "q", function()
    vim.cmd("close")
    refresh_ui()
  end, { buffer = buf, nowait = true })

  vim.api.nvim_buf_set_name(buf, title)
  vim.cmd("botright split | buffer " .. buf)

  local env = get_cmd_env(cmd[1])

  if env then
    local env_copy = vim.deepcopy(env)
    table.insert(env_copy, 1, "env")

    cmd = vim.list_extend(env_copy, cmd)
  else
    cmd = { unpack(cmd) }
  end

  vim.fn.jobstart(cmd, {
    cwd = cwd,
    term = true,
    on_exit = function(_, code)
      if code == 0 then
        return
      end

      vim.schedule(function()
        if code == 2 then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
          return
        end

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        lines = trim_empty_lines(lines)

        local preview = (#lines <= 6) and table.concat(lines, "\n")
          or table.concat(vim.list_slice(lines, 1, 3), "\n")
            .. "\n...omitted...\n"
            .. table.concat(vim.list_slice(lines, #lines - 2, #lines), "\n")

        notify(("cmd exited %d\n%s"):format(code, preview), "ERROR")
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end)
    end,
  })

  vim.cmd("startinsert")
end

------------------------------------------------------------------
-- Process Management
------------------------------------------------------------------

---Run a CLI command.
---@param cmd string[]
---@param on_done? fun(code: integer, out: string, err: string)
---@param timeout? integer Timeout in milliseconds
---@return Cmd.RunResult? result Only if synchronous
local function run_cli(cmd, on_done, timeout)
  timeout = timeout or 30000 -- 30 seconds
  local is_sync = on_done == nil
  local result ---@type Cmd.RunResult?

  if is_sync then
    on_done = function(code, out, err)
      result = { code = code, out = out, err = err }
    end
  end

  local stdout, stderr = uv.new_pipe(false), uv.new_pipe(false)
  local out_chunks, err_chunks = {}, {}

  local process = uv.spawn(cmd[1], {
    args = vim.list_slice(cmd, 2),
    cwd = cwd,
    stdio = { nil, stdout, stderr },
    env = nil,
    uid = nil,
    gid = nil,
    verbatim = nil,
    detached = nil,
    hide = nil,
  }, function(code)
    if stdout and not stdout:is_closing() then
      stdout:close()
    end
    if stderr and not stderr:is_closing() then
      stderr:close()
    end
    if on_done then
      on_done(code, stream_tostring(out_chunks), stream_tostring(err_chunks))
    end
  end)

  if stdout then
    read_stream(stdout, out_chunks)
  end
  if stderr then
    read_stream(stderr, err_chunks)
  end

  local timer = uv.new_timer()
  if timer then
    timer:start(timeout, 0, function()
      if process and not process:is_closing() then
        process:kill("sigkill")
        if on_done then
          on_done(124, "", "process killed after timeout")
        end
      end
      timer:close()
    end)
  end

  if is_sync then
    vim.wait(timeout + 100, function()
      return result ~= nil
    end, 10)
    return result
  end
end

------------------------------------------------------------------
-- Execution Dispatcher
------------------------------------------------------------------

---Run `cmd` command in terminal (interactive) or buffer (info).
---@param args string[]
---@param bang boolean
local function run(args, bang)
  last_cmd = args
  if bang then
    show_terminal(args, "cmd://" .. table.concat(args, " "))
  else
    start_cmd_spinner("cmd", table.concat(args, " "))

    local res = run_cli(args)

    if not res then
      stop_cmd_spinner(false)
      notify(string.format("failed to get response from cli with cmd %s", table.concat(args, " ")), "ERROR")
      return
    end

    stop_cmd_spinner(res.code == 0)

    local out = res.out
    local lines = vim.split(out, "\n")
    lines = trim_empty_lines(lines)

    if res.code ~= 0 then
      notify(res.err ~= "" and res.err or res.out, "ERROR")
    else
      if #lines > 0 then
        show_buffer(lines, "cmd://" .. table.concat(args, " "))
      else
        notify("Nothing to show after trimmed", "WARN")
      end
      refresh_ui()
    end
  end
end

------------------------------------------------------------------
-- Public Interface
------------------------------------------------------------------

---@type Cmd.Config
M.config = {}

---@class Cmd.Config
---@field force_terminal? table<string, string[]> Detect any of these command to force terminal
---@field create_usercmd? table<string, string> Create user commands for these executables if it does'nt exists
---@field env? table<string, string[]> Environment variables to set for the command
M.defaults = {
  force_terminal = {},
  create_usercmd = {},
  env = {},
}

function M.create_usercmd_if_not_exists()
  local existing_cmds = vim.api.nvim_get_commands({})
  for executable, cmd_name in pairs(M.config.create_usercmd) do
    if vim.fn.executable(executable) == 1 and not existing_cmds[cmd_name] then
      vim.api.nvim_create_user_command(cmd_name, function(opts)
        local args = { executable, unpack(opts.fargs) }
        local bang = opts.bang

        local force_terminal_executable = M.config.force_terminal[executable] or {}

        if not vim.tbl_isempty(force_terminal_executable) then
          for _, arg in ipairs(args) do
            if vim.tbl_contains(force_terminal_executable, arg) then
              bang = true
              break
            end
          end
        end

        run(args, bang)
      end, {
        nargs = "*",
        bang = true,
        desc = "Auto-generated command for " .. executable,
      })
    else
      notify(("%s is not executable or already exists"):format(executable), "WARN")
    end
  end
end

---Setup the `:Cmd` command.
---@param user_config? Cmd.Config
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  if M.config.create_usercmd and not vim.tbl_isempty(M.config.create_usercmd) then
    M.create_usercmd_if_not_exists()
  end

  vim.api.nvim_create_user_command("Cmd", function(opts)
    local bang = opts.bang or false
    local args = opts.fargs

    if opts.bang and opts.args == "!" then
      if vim.tbl_isempty(last_cmd) then
        notify("No previous command to re-run", "WARN")
        return
      end
      args = last_cmd
      bang = true
    end

    if #args < 1 then
      notify("No arguments provided", "WARN")
      return
    end

    local executable = args[1]

    if vim.fn.executable(executable) == 0 then
      notify(("%s is not executable"):format(executable), "WARN")
      return
    end

    local force_terminal_executable = M.config.force_terminal[executable] or {}

    if not vim.tbl_isempty(force_terminal_executable) then
      for _, arg in ipairs(args) do
        if vim.tbl_contains(force_terminal_executable, arg) then
          bang = true
          break
        end
      end
    end

    run(args, bang)
  end, {
    nargs = "*",
    bang = true,
    desc = "Run CLI command",
  })
end

return M
