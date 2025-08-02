---@class Gh
local M = {}

------------------------------------------------------------------
-- Constants & Setup
------------------------------------------------------------------

local uv = vim.uv or vim.loop

---@type boolean
local has_gh = vim.fn.executable("gh") == 1

---@type string
local cwd = vim.fn.expand("%:p:h")
if not uv.fs_stat(cwd .. "/.git") then
  cwd = vim.fn.getcwd()
end

------------------------------------------------------------------
-- Type Aliases
------------------------------------------------------------------

---@alias Gh.LogLevel "INFO"|"WARN"|"ERROR"

---@class Gh.RunResult
---@field code integer
---@field out string
---@field err string

------------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------------

---Display a notification.
---@param msg string
---@param lvl Gh.LogLevel
local function notify(msg, lvl)
  vim.notify(msg, vim.log.levels[lvl:upper()], { title = "gh" })
end

---Check if given CLI args are for help/version output.
---@param args string[]
---@return boolean
local function is_info(args)
  local matches = { "help", "--help", "--version" }
  for _, arg in ipairs(args) do
    if vim.tbl_contains(matches, arg) then
      return true
    end
  end
  return false
end

---@param chunks string[]
---@return string
local function stream_tostring(chunks)
  return (table.concat(chunks):gsub("\r", "\n"))
end

---Start reading a stream into a buffer.
---@param pipe uv.uv_stream_t
---@param buffer string[]
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

------------------------------------------------------------------
-- UI Helpers
------------------------------------------------------------------

---Show output in a scratch buffer (readonly, vsplit).
---@param out string
---@param title string
local function show_buffer(out, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(out, "\n"))
  vim.bo[buf].filetype = "gh"
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
  vim.bo[buf].filetype = "gh"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, nowait = true })

  vim.api.nvim_buf_set_name(buf, title)
  vim.cmd("botright split | buffer " .. buf)

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
        local preview = (#lines <= 6) and table.concat(lines, "\n")
          or table.concat(vim.list_slice(lines, 1, 3), "\n")
            .. "\n...omitted...\n"
            .. table.concat(vim.list_slice(lines, #lines - 2, #lines), "\n")

        notify(("gh exited %d\n%s"):format(code, preview), "ERROR")
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
---@return Gh.RunResult? result Only if synchronous
local function run_cli(cmd, on_done, timeout)
  timeout = timeout or 30000 -- 30 seconds
  local is_sync = on_done == nil
  local result ---@type Gh.RunResult?

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
          on_done(124, "", "gh: process killed after timeout")
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

---Run `gh` command in terminal (interactive) or buffer (info).
---@param args string[]
---@param bang boolean
local function run(args, bang)
  local cmd = vim.list_extend({ "gh" }, args)

  if bang then
    show_terminal(cmd, "gh://" .. table.concat(args, " "))
  else
    -- scratch buffer mode
    local res = run_cli(cmd)
    if not res then
      notify(string.format("failed to get response from cli with cmd %s", table.concat(cmd, " ")), "ERROR")
      return
    end
    if res.code ~= 0 then
      notify(res.err ~= "" and res.err or res.out, "ERROR")
    elseif res.out ~= "" then
      show_buffer(res.out, "gh://" .. table.concat(args, " "))
    end
  end
end

------------------------------------------------------------------
-- Public Interface
------------------------------------------------------------------

---Setup the `:Gh` command.
function M.setup()
  vim.api.nvim_create_user_command("Gh", function(opts)
    if not has_gh then
      notify("`gh` not found", "ERROR")
      return
    end

    local bang = opts.bang
    local args = vim.split(opts.args or "", "%s+", { trimempty = true })

    if #args == 0 then
      notify("No arguments provided", "WARN")
      return
    end

    if bang or not is_info(args) then
      run(args, true)
    else
      run(args, false)
    end
  end, {
    nargs = "*",
    bang = true,
    desc = "Run GitHub CLI command",
  })
end

return M
