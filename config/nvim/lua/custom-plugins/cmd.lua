local uv = vim.uv or vim.loop

---@class Cmd
local M = {}

------------------------------------------------------------------
-- Constants & Setup
------------------------------------------------------------------

---@type string
local cwd

---@type string[]
local last_cmd = {}

---@type string[]
local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@type integer
local next_spinner_id = 0

---@type table<integer, uv.uv_process_t>
local active_jobs = {}

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

local function ensure_cwd()
  if cwd then
    return
  end
  cwd = vim.fn.expand("%:p:h")
  if not uv.fs_stat(cwd .. "/.git") then
    cwd = vim.fn.getcwd()
  end
end

---Display a notification.
---@param msg string
---@param lvl Cmd.LogLevel
---@param opts? table
---@return nil
local function notify(msg, lvl, opts)
  opts = opts or {}
  opts.title = opts.title or "cmd"
  vim.notify(msg, vim.log.levels[lvl:upper()], opts)
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
  vim.schedule(function()
    vim.cmd("redraw!")
    vim.cmd("checktime")
  end)
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

---@class Cmd.Spinner
---@field timer uv.uv_timer_t|nil
---@field active boolean
---@field msg string
---@field title string
---@field cmd string
local spin_state = {}

---Start a spinner.
---@param title string
---@param msg string
---@param cmd string
---@return integer spinner_id
local function start_cmd_spinner(title, msg, cmd)
  next_spinner_id = next_spinner_id + 1
  local spinner_id = next_spinner_id

  local timer = uv.new_timer()
  if timer then
    spin_state[spinner_id] = {
      timer = timer,
      active = true,
      msg = string.format("[#%s] running `%s`", spinner_id, msg),
      title = title,
      cmd = cmd,
    }
  end

  -- local index for this spinner only
  local idx = 1
  local last = vim.uv.hrtime()

  if timer then
    timer:start(0, 100, function()
      vim.schedule(function()
        if not spin_state[spinner_id] or not spin_state[spinner_id].active then
          return
        end

        local now = vim.uv.hrtime()

        if now - last > 80e6 then
          idx = (idx % #spinner_chars) + 1
          last = now
        end

        local msg_with_spinner = string.format("%s %s", spinner_chars[idx], spin_state[spinner_id].msg)

        notify(msg_with_spinner, "INFO", {
          id = "cmd_progress_" .. spinner_id,
          title = spin_state[spinner_id].title,
        })
      end)
    end)
  end

  return spinner_id
end

---Stop a spinner.
---@param spinner_id integer
---@param status "completed"|"failed"|"cancelled"
---@return nil
local function stop_cmd_spinner(spinner_id, status)
  if not spinner_id or not spin_state[spinner_id] or not spin_state[spinner_id].active then
    return
  end

  local st = spin_state[spinner_id]
  st.active = false
  st.timer:stop()
  st.timer:close()
  spin_state[spinner_id] = nil

  local icon_map = {
    completed = " ",
    failed = " ",
    cancelled = " ",
  }

  local level_map = {
    completed = "INFO",
    failed = "ERROR",
    cancelled = "WARN",
  }

  local icon = icon_map[status] or " "

  local msg = string.format("%s [#%s] %s `%s`", icon, spinner_id, status, st.cmd)
  local level = level_map[status] or vim.log.levels.ERROR

  vim.schedule(function()
    notify(msg, level, {
      id = "cmd_progress_" .. spinner_id,
      title = "cmd",
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
  vim.schedule(function()
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
  end)
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
      refresh_ui()

      if code == 0 then
        return
      end

      vim.schedule(function()
        -- 130 = Interrupted (Ctrl+C)
        if code == 130 then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
          return
        end

        local cmd_string = table.concat(cmd, " ")

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        lines = trim_empty_lines(lines)

        local preview = (#lines <= 6) and table.concat(lines, "\n")
          or table.concat(vim.list_slice(lines, 1, 3), "\n")
            .. "\n...omitted...\n"
            .. table.concat(vim.list_slice(lines, #lines - 2, #lines), "\n")

        notify(string.format("`%s` exited %d\n%s", cmd_string, code, preview), "ERROR")
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
---@param spinner_id integer
---@param on_done fun(code: integer, out: string, err: string, is_cancelled?: boolean)
---@param timeout? integer Timeout in milliseconds
---@return Cmd.RunResult? result Only if synchronous
local function run_cli(cmd, spinner_id, on_done, timeout)
  timeout = timeout or M.config.timeout

  ensure_cwd()

  -- Create a coroutine
  local stdout, stderr = uv.new_pipe(false), uv.new_pipe(false)
  local out_chunks, err_chunks = {}, {}
  local done = false
  ---@type uv.uv_timer_t|nil
  local timer

  local function finish(code, out, err)
    if done then
      return
    end
    done = true

    -- stop & close the timer so it can never fire
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end

    if stdout and not stdout:is_closing() then
      stdout:close()
    end
    if stderr and not stderr:is_closing() then
      stderr:close()
    end

    local is_cancelled = code == 130
    local final_out = out or ""
    local final_err = err or ""

    vim.schedule(function()
      on_done(code, final_out, final_err, is_cancelled)
    end)
  end

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
  }, function(code, signal)
    active_jobs[spinner_id] = nil

    if signal == 2 then
      code = 130
    end -- SIGINT
    if signal == 15 then
      code = 143
    end -- SIGTERM
    if signal == 9 then
      code = 137
    end -- SIGKILL

    finish(code, stream_tostring(out_chunks), stream_tostring(err_chunks))
  end)

  if not process then
    on_done(127, "", string.format("failed to spawn process: %s", cmd[1]))
    return
  end

  active_jobs[spinner_id] = process

  if stdout then
    read_stream(stdout, out_chunks)
  end
  if stderr then
    read_stream(stderr, err_chunks)
  end

  -- Set up timeout
  timer = uv.new_timer()
  if timer and timeout then
    timer:start(timeout, 0, function()
      if process and not process:is_closing() then
        process:kill("sigterm")
        vim.defer_fn(function()
          if process and not process:is_closing() then
            process:kill("sigkill")
          end
        end, 1000)
      end
      timer:close()
      finish(124, "", string.format("process killed after timeout: %s", cmd[1]))
    end)
  end
end

---@param job uv.uv_process_t|nil
local function cancel_with_fallback(job)
  if not job or job:is_closing() then
    return
  end

  job:kill("sigint")
  vim.defer_fn(function()
    if job and not job:is_closing() then
      job:kill("sigkill")
    end
  end, 1000) -- give 1 second to terminate cleanly
end

---Cancel the currently running command.
---@param spinner_id number|nil
---@param all boolean
---@return nil
local function cancel_cmd(spinner_id, all)
  if all then
    local count = 0
    for id, job in pairs(active_jobs) do
      if job and not job:is_closing() then
        cancel_with_fallback(job)
        active_jobs[id] = nil
        count = count + 1
      end
    end
    notify(string.format("Cancelled %d running commands", count), "WARN")
    return
  end

  local id = spinner_id or next_spinner_id
  local job = active_jobs[id]

  if job and not job:is_closing() then
    cancel_with_fallback(job)
    active_jobs[id] = nil
  else
    notify("No active command to cancel", "WARN")
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
    local spinner_id = start_cmd_spinner("cmd", table.concat(args, " "), table.concat(args, " "))

    run_cli(args, spinner_id, function(code, out, err, is_cancelled)
      local status

      if is_cancelled then
        status = "cancelled"
      else
        status = code ~= 0 and "failed" or "completed"

        local lines_string = out

        if status == "failed" then
          lines_string = err ~= "" and err or out
        end

        local lines = vim.split(lines_string, "\n")
        lines = trim_empty_lines(lines)

        if #lines > 0 then
          show_buffer(lines, "cmd://" .. table.concat(args, " ") .. "-" .. spinner_id)
        end

        if status == "completed" then
          refresh_ui()
        end
      end

      stop_cmd_spinner(spinner_id, status)
    end)
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
---@field timeout? integer Job timeout in ms. Default: 30000
M.defaults = {
  force_terminal = {},
  create_usercmd = {},
  env = {},
  timeout = 30000,
}

function M.create_usercmd_if_not_exists()
  local existing_cmds = vim.api.nvim_get_commands({})
  for executable, cmd_name in pairs(M.config.create_usercmd) do
    if vim.fn.executable(executable) == 1 and not existing_cmds[cmd_name] then
      vim.api.nvim_create_user_command(cmd_name, function(opts)
        local fargs = vim.deepcopy(opts.fargs)

        -- to support expanding the args like %
        for i, arg in ipairs(fargs) do
          fargs[i] = vim.fn.expand(arg)
        end

        local args = { executable, unpack(fargs) }
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
    local args = vim.deepcopy(opts.fargs)

    -- to support expanding the args like %
    for i, arg in ipairs(args) do
      args[i] = vim.fn.expand(arg)
    end

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
    desc = "Run CLI command (add ! to run in terminal, add !! to rerun last command in terminal)",
  })

  vim.api.nvim_create_user_command("CmdCancel", function(opts)
    local id = tonumber(opts.args)
    cancel_cmd(id, opts.bang)
  end, {
    bang = true,
    nargs = "?",
    desc = "Cancel the currently running Cmd (add ! to cancel all)",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      for _, st in pairs(spin_state) do
        if st.timer and not st.timer:is_closing() then
          st.timer:stop()
          st.timer:close()
        end
      end
    end,
  })
end

return M
