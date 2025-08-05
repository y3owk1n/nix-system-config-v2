local uv = vim.uv or vim.loop

---@class Cmd
local Cmd = {}

---@class Cmd.Helpers
local H = {}

---@class Cmd.UI
local U = {}

---@class Cmd.Core
local C = {}

------------------------------------------------------------------
-- Constants & Setup
------------------------------------------------------------------

---@type string
local cwd

---@type string[]
local last_cmd = {}

---@type string[]
local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@type table<integer, uv.uv_process_t>
local active_jobs = {}

---@type table<string, string>
local temp_script_cache = {}

---@class Cmd.Spinner
---@field timer uv.uv_timer_t|nil
---@field active boolean
---@field msg string
---@field title string
---@field cmd string
local spinner_state = {}

---@class Cmd.CommandHistory
---@field id integer
---@field cmd string[]
---@field timestamp? number
---@field type "normal"|"interactive"
---@field status Cmd.CommandStatus

---@alias Cmd.CommandStatus "success"|"failed"|"cancelled"|"running"

---@type Cmd.CommandHistory[]
local command_history = {}

---@type table<Cmd.CommandStatus, string>
local icon_map = {
  success = " ",
  failed = " ",
  cancelled = " ",
}

---@type table<Cmd.CommandStatus, string>
local level_map = {
  success = "INFO",
  failed = "ERROR",
  cancelled = "WARN",
}

---@type table<Cmd.CommandStatus, string>
local hl_groups = {
  success = "MoreMsg",
  failed = "ErrorMsg",
  cancelled = "WarningMsg",
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
-- Helpers
------------------------------------------------------------------

---Ensure that the current working directory is set.
function H.ensure_cwd()
  local buf_path = vim.fn.expand("%:p:h")

  if buf_path and buf_path ~= "" and vim.fn.isdirectory(buf_path) == 1 then
    cwd = buf_path
  else
    cwd = vim.fn.getcwd()
  end
end

---Display a notification.
---@param msg string
---@param lvl Cmd.LogLevel
---@param opts? table
---@return nil
function H.notify(msg, lvl, opts)
  opts = opts or {}
  opts.title = opts.title or "cmd"
  vim.notify(msg, vim.log.levels[lvl:upper()], opts)
end

---Stream chunks to a string.
---@param chunks string[]
---@return string
function H.stream_tostring(chunks)
  return (table.concat(chunks):gsub("\r", "\n"))
end

---Start reading a stream into a buffer.
---@param pipe uv.uv_stream_t
---@param buffer string[]
---@return nil
function H.read_stream(pipe, buffer)
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
function H.trim_empty_lines(lines)
  return vim.tbl_filter(function(s)
    return s ~= ""
  end, lines)
end

---Get the environment variables for a command.
---@param executable string
---@return string[]|nil
function H.get_cmd_env(executable)
  local env = Cmd.config.env or {}

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

---Sanitize the output of a file handle.
---@param lines string[]
---@return string[]
function H.sanitize_file_output(lines)
  ---@type string[]
  local cleaned = {}

  for _, line in ipairs(lines) do
    -- Strip ANSI escape codes
    line = line:gsub("\27%[[0-9;]*m", "")

    -- Trim trailing whitespace
    line = line:gsub("^%s+", ""):gsub("%s+$", "")

    -- Remove user-specified prompt
    if Cmd.config.completion.prompt_pattern_to_remove then
      line = line:gsub(Cmd.config.completion.prompt_pattern_to_remove, "")
    end

    -- Trim leading & trailing whitespace
    line = line:gsub("^%s+", ""):gsub("%s+$", "")

    -- Split the line by tab
    local splitted_item = vim.split(line, "\t")

    -- Get the first item, which is the command
    local first = splitted_item[1]

    -- Only add the first item if it's not empty
    if first and first ~= "" then
      table.insert(cleaned, first)
    end
  end

  return cleaned
end

---Get the right shell arguments for the given shell.
---@param shell string
---@param script_path string
---@param input string
---@return string
function H.shell_args(shell, script_path, input)
  local shell_name = vim.fn.fnamemodify(shell, ":t")

  if shell_name == "fish" then
    return string.format("%s %s %q", shell, script_path, input)
  elseif shell_name == "zsh" then
    return string.format("%s %s %q", shell, script_path, input)
  elseif shell_name == "bash" then
    return string.format("%s %s %q", shell, script_path, input)
  else
    error("Unsupported shell: " .. shell)
  end
end

---Write a temporary shell script.
---@param shell string
---@return string|nil
function H.write_temp_script(shell)
  if temp_script_cache[shell] then
    return temp_script_cache[shell]
  end

  local path = vim.fn.tempname() .. ".sh"
  local content = ""

  if shell:find("fish") then
    content = [[
#!/usr/bin/env fish
set -l input "$argv"
complete -C "$input"
]]
  elseif shell:find("zsh") then
    -- TODO: not tested yet, as i don't use zsh, come back later
    content = [[
#!/usr/bin/env zsh
autoload -U +X compinit && compinit -u
autoload -U +X bashcompinit && bashcompinit -u
setopt no_aliases

local line=$1
BUFFER=$line
CURSOR=${#line}
zle -C my-complete complete-word _main_complete
zle my-complete
]]
  else -- bash or default
    -- TODO: not tested yet, as i don't use bash, come back later
    content = [[
#!/usr/bin/env bash
COMP_LINE="$1"
COMP_POINT=${#1}
read -ra COMP_WORDS <<< "$COMP_LINE"
COMP_CWORD=${#COMP_WORDS[@]}

cmd="${COMP_WORDS[0]}"
type _completion_loader &>/dev/null && _completion_loader "$cmd" &>/dev/null
type "_$cmd" &>/dev/null && "_$cmd" &>/dev/null

for i in "${COMPREPLY[@]}"; do
  printf '%s\n' "$i"
done
]]
  end

  local f = io.open(path, "w")
  if not f then
    return nil
  end
  f:write(content)
  f:close()
  vim.fn.system({ "chmod", "+x", path })

  temp_script_cache[shell] = path

  return path
end

------------------------------------------------------------------
-- UI
------------------------------------------------------------------

---Start a spinner.
---@param title string
---@param msg string
---@param cmd string
---@param command_id integer
function U.start_cmd_spinner(title, msg, cmd, command_id)
  local timer = uv.new_timer()
  if timer then
    spinner_state[command_id] = {
      timer = timer,
      active = true,
      msg = string.format("[#%s] running `%s`", command_id, msg),
      title = title,
      cmd = cmd,
    }
  end

  -- local index for this spinner only
  local idx = 1
  local last = uv.hrtime()

  if timer then
    timer:start(0, 100, function()
      vim.schedule(function()
        if not spinner_state[command_id] or not spinner_state[command_id].active then
          return
        end

        local now = vim.uv.hrtime()

        if now - last > 80e6 then
          idx = (idx % #spinner_chars) + 1
          last = now
        end

        local msg_with_spinner = string.format("%s %s", spinner_chars[idx], spinner_state[command_id].msg)

        H.notify(msg_with_spinner, "INFO", {
          id = "cmd_progress_" .. command_id,
          title = spinner_state[command_id].title,
        })
      end)
    end)
  end
end

---Stop a spinner.
---@param spinner_id integer
---@param status Cmd.CommandStatus
---@return nil
function U.stop_cmd_spinner(spinner_id, status)
  if not spinner_id or not spinner_state[spinner_id] or not spinner_state[spinner_id].active then
    return
  end

  local st = spinner_state[spinner_id]
  st.active = false
  st.timer:stop()
  st.timer:close()
  spinner_state[spinner_id] = nil

  local icon = icon_map[status] or " "

  local msg = string.format("%s [#%s] %s `%s`", icon, spinner_id, status, st.cmd)
  local level = level_map[status] or vim.log.levels.ERROR

  vim.schedule(function()
    H.notify(msg, level, {
      id = "cmd_progress_" .. spinner_id,
      title = "cmd",
    })
  end)
end

---Show output in a scratch buffer (readonly, vsplit).
---@param lines string[]
---@param title string
---@param post_hook? fun(buf: integer, lines: string[])
function U.show_buffer(lines, title, post_hook)
  local old_buf = vim.fn.bufnr(title)
  if old_buf ~= -1 then
    vim.api.nvim_buf_delete(old_buf, { force = true })
  end

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

    if post_hook then
      post_hook(buf, lines)
    end
  end)
end

---Show output in a terminal buffer.
---@param cmd string[]
---@param title string
---@param command_id integer
function U.show_terminal(cmd, title, command_id)
  C.track_cmd({
    id = command_id,
    cmd = cmd,
    type = "interactive",
    status = "running",
  })

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

  local env = H.get_cmd_env(cmd[1])

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
      U.refresh_ui()

      if code == 0 then
        C.track_cmd({
          id = command_id,
          cmd = cmd,
          type = "interactive",
          status = "success",
        })
        return
      end

      vim.schedule(function()
        -- 130 = Interrupted (Ctrl+C)
        if code == 130 then
          C.track_cmd({
            id = command_id,
            cmd = cmd,
            type = "interactive",
            status = "cancelled",
          })
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
          return
        end

        local cmd_string = table.concat(cmd, " ")

        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        lines = H.trim_empty_lines(lines)

        local preview = (#lines <= 6) and table.concat(lines, "\n")
          or table.concat(vim.list_slice(lines, 1, 3), "\n")
            .. "\n...omitted...\n"
            .. table.concat(vim.list_slice(lines, #lines - 2, #lines), "\n")

        H.notify(string.format("`%s` exited %d\n%s", cmd_string, code, preview), "ERROR")

        C.track_cmd({
          id = command_id,
          cmd = cmd,
          type = "interactive",
          status = "failed",
        })
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end)
    end,
  })

  vim.cmd("startinsert")
end

function U.refresh_ui()
  vim.schedule(function()
    vim.cmd("redraw!")
    vim.cmd("checktime")
  end)
end

------------------------------------------------------------------
-- Core
------------------------------------------------------------------

---Run a CLI command.
---@param cmd string[]
---@param spinner_id integer
---@param on_done fun(code: integer, out: string, err: string, is_cancelled?: boolean)
---@param timeout? integer Timeout in milliseconds
---@return Cmd.RunResult? result Only if synchronous
function C.exec_cli(cmd, spinner_id, on_done, timeout)
  timeout = timeout or Cmd.config.timeout

  H.ensure_cwd()

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

    finish(code, H.stream_tostring(out_chunks), H.stream_tostring(err_chunks))
  end)

  if not process then
    on_done(127, "", string.format("failed to spawn process: %s", cmd[1]))
    return
  end

  active_jobs[spinner_id] = process

  if stdout then
    H.read_stream(stdout, out_chunks)
  end
  if stderr then
    H.read_stream(stderr, err_chunks)
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
function C.cancel_with_fallback(job)
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
        C.cancel_with_fallback(job)
        active_jobs[id] = nil
        count = count + 1
      end
    end
    H.notify(string.format("Cancelled %d running commands", count), "WARN")
    return
  end

  local id = spinner_id or #command_history
  local job = active_jobs[id]

  if job and not job:is_closing() then
    C.cancel_with_fallback(job)
    active_jobs[id] = nil
  else
    H.notify("No active command to cancel", "WARN")
  end
end

---Get the cached shell completion for the given executable.
---@param executable? string
---@param lead_args string
---@param cmd_line string
---@param cursor_pos integer
function C.cached_shell_complete(executable, lead_args, cmd_line, cursor_pos)
  if Cmd.config.completion.enabled == false then
    return {}
  end

  H.ensure_cwd()

  --- this should be the root `Cmd` call rather than user defined commands
  --- we can then set the right executable and reconstruct the cmd_line to let it work normally
  if not executable then
    local cmd_line_table = vim.split(cmd_line, " ")
    table.remove(cmd_line_table, 1)

    executable = cmd_line_table[1]

    cmd_line = table.concat(cmd_line_table, " ")
  end

  local shell = Cmd.config.completion.shell or vim.env.SHELL or "/bin/bash"
  local script_path = H.write_temp_script(shell)
  if not script_path then
    H.notify("Failed to create temp script", "ERROR")
    return {}
  end

  -- Build the exact line the shell would see
  local full_line = cmd_line:sub(1, cursor_pos)

  local full_line_table = vim.split(full_line, " ")
  full_line_table[1] = executable
  full_line = table.concat(full_line_table, " ")

  local result = vim
    .system({ shell, script_path, full_line }, {
      text = true,
      cwd = cwd,
    })
    :wait()

  if result.code ~= 0 then
    H.notify("Shell completion failed with exit code: " .. result.code, "WARN")
    return {}
  end

  local lines = vim.split(result.stdout, "\n")

  local completions = H.sanitize_file_output(lines)

  return completions
end

---Run `cmd` command in terminal (interactive) or buffer (info).
---@param args string[]
---@param bang boolean
function C.run_cmd(args, bang)
  last_cmd = args

  local command_id = #command_history + 1

  if bang then
    U.show_terminal(args, "cmd://" .. table.concat(args, " "), command_id)
  else
    C.track_cmd({
      id = command_id,
      cmd = args,
      type = "normal",
      status = "running",
    })

    U.start_cmd_spinner("cmd", table.concat(args, " "), table.concat(args, " "), command_id)

    C.exec_cli(args, command_id, function(code, out, err, is_cancelled)
      ---@type Cmd.CommandStatus
      local status

      if is_cancelled then
        status = "cancelled"
      else
        status = code == 0 and "success" or "failed"

        local text = table.concat(H.trim_empty_lines({ err, out }), "\n")

        local lines = vim.split(text, "\n")
        lines = H.trim_empty_lines(lines)

        for i, line in ipairs(lines) do
          --- Strip ANSI escape codes
          lines[i] = line:gsub("\27%[[0-9;]*m", "")
        end

        if #lines > 0 then
          U.show_buffer(lines, "cmd://" .. table.concat(args, " ") .. "-" .. command_id)
        else
          H.notify("Completed but no output lines", "INFO")
        end

        if status == "success" then
          U.refresh_ui()
        end
      end

      U.stop_cmd_spinner(command_id, status)

      C.track_cmd({
        id = command_id,
        cmd = args,
        type = "normal",
        status = status,
      })
    end)
  end
end

---@param opts Cmd.CommandHistory
function C.track_cmd(opts)
  if #command_history > 100 then
    table.remove(command_history, 1)
  end

  opts.timestamp = os.time()
  command_history[opts.id] = opts
end

------------------------------------------------------------------
-- Public Interface
------------------------------------------------------------------

---@type Cmd.Config
Cmd.config = {}

---@class Cmd.Config.Completion
---@field enabled? boolean Whether to enable completion. Default: false
---@field shell? string Shell to use for the completion. Default: vim.env.SHELL
---@field prompt_pattern_to_remove? string Regex pattern to remove from the output, e.g. "^"

---@class Cmd.Config
---@field force_terminal? table<string, string[]> Detect any of these command to force terminal
---@field create_usercmd? table<string, string> Create user commands for these executables if it does'nt exists
---@field env? table<string, string[]> Environment variables to set for the command
---@field timeout? integer Job timeout in ms. Default: 30000
---@field completion? Cmd.Config.Completion Completion configuration
Cmd.defaults = {
  force_terminal = {},
  create_usercmd = {},
  env = {},
  timeout = 30000,
  completion = {
    enabled = false,
    shell = vim.env.SHELL or "/bin/sh",
  },
}

function Cmd.create_usercmd_if_not_exists()
  local existing_cmds = vim.api.nvim_get_commands({})
  for executable, cmd_name in pairs(Cmd.config.create_usercmd) do
    if vim.fn.executable(executable) == 1 and not existing_cmds[cmd_name] then
      vim.api.nvim_create_user_command(cmd_name, function(opts)
        local fargs = vim.deepcopy(opts.fargs)

        -- to support expanding the args like %
        for i, arg in ipairs(fargs) do
          fargs[i] = vim.fn.expand(arg)
        end

        local args = { executable, unpack(fargs) }
        local bang = opts.bang

        local force_terminal_executable = Cmd.config.force_terminal[executable] or {}

        if not vim.tbl_isempty(force_terminal_executable) then
          for _, value in ipairs(force_terminal_executable) do
            local args_string = table.concat(args, " ")
            local matched = string.find(args_string, value, 1, true) ~= nil

            if matched == true then
              bang = true
              break
            end
          end
        end

        C.run_cmd(args, bang)
      end, {
        nargs = "*",
        bang = true,
        complete = function(...)
          return C.cached_shell_complete(executable, ...)
        end,
        desc = "Auto-generated command for " .. executable,
      })
    else
      H.notify(("%s is not executable or already exists"):format(executable), "WARN")
    end
  end
end

---Setup the `:Cmd` command.
---@param user_config? Cmd.Config
function Cmd.setup(user_config)
  Cmd.config = vim.tbl_deep_extend("force", Cmd.defaults, user_config or {})

  if Cmd.config.create_usercmd and not vim.tbl_isempty(Cmd.config.create_usercmd) then
    Cmd.create_usercmd_if_not_exists()
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
        H.notify("No previous command to re-run", "WARN")
        return
      end
      args = last_cmd
      bang = true
    end

    if #args < 1 then
      H.notify("No arguments provided", "WARN")
      return
    end

    local executable = args[1]

    if vim.fn.executable(executable) == 0 then
      H.notify(("%s is not executable"):format(executable), "WARN")
      return
    end

    local force_terminal_executable = Cmd.config.force_terminal[executable] or {}

    if not vim.tbl_isempty(force_terminal_executable) then
      for _, value in pairs(force_terminal_executable) do
        local args_string = table.concat(args, " ")
        local matched = string.find(args_string, value, 1, true) ~= nil

        if matched == true then
          bang = true
          break
        end
      end
    end

    C.run_cmd(args, bang)
  end, {
    nargs = "*",
    bang = true,
    complete = function(...)
      return C.cached_shell_complete(nil, ...)
    end,
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
      -- stop all timers
      for _, st in pairs(spinner_state) do
        if st.timer and not st.timer:is_closing() then
          st.timer:stop()
          st.timer:close()
        end
      end

      -- delete all temp scripts
      for _, path in pairs(temp_script_cache) do
        pcall(vim.fn.delete, path)
      end
    end,
  })

  vim.api.nvim_create_user_command("CmdHistory", function()
    local history = vim.deepcopy(command_history)

    if #history == 0 then
      H.notify("No command history", "INFO")
      return
    end

    ---@type table<integer, { text: string|osdate, hl_group: string }>[]
    local segments = {}

    local separator = {
      text = " ",
    }

    for i = #history, 1, -1 do
      local entry = history[i]
      local status_icon = icon_map[entry.status] or "?"

      local cmd_str = table.concat(entry.cmd, " ")
      local timetamp = entry.timestamp

      local pretty_time = os.date("%Y-%m-%d %H:%M:%S", timetamp)

      segments[i] = {
        {
          text = string.format("#%d", entry.id),
          hl_group = "Identifier",
        },
        separator,
        {
          text = pretty_time,
          hl_group = "Comment",
        },
        separator,
        {
          text = status_icon,
          hl_group = hl_groups[entry.status],
        },
        separator,
        {
          text = cmd_str,
          hl_group = hl_groups[entry.status],
        },
      }
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

    U.show_buffer(lines, "cmd://history", function(buf)
      local ns = vim.api.nvim_create_namespace("cmd_history")
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
    end)
  end, {
    desc = "History",
  })
end

return Cmd
