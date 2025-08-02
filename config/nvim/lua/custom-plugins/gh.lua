local M = {}

local has_gh = vim.fn.executable("gh") == 1

---@type integer|nil
local term_buf

local cwd = vim.fn.expand("%:p:h")
if not vim.loop.fs_stat(cwd .. "/.git") then
  cwd = vim.fn.getcwd()
end

------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------

---Display a notification message.
---@param msg string
---@param lvl "INFO"|"WARN"|"ERROR"
local function notify(msg, lvl)
  vim.notify(msg, vim.log.levels[lvl:upper()], {
    title = "gh",
  })
end

---Escape and join shell command arguments.
---@param parts string[]
---@return string
local function shellescape(parts)
  local escaped = {}
  for _, s in ipairs(parts) do
    s = tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"')
    escaped[#escaped + 1] = '"' .. s .. '"'
  end
  return table.concat(escaped, " ")
end

---Determine if the command is informational (help/version).
---@param args string[]
---@return boolean
local function is_info(args)
  local matches = { "--help", "--version" }
  for _, arg in ipairs(args) do
    if vim.tbl_contains(matches, arg) then
      return true
    end
  end

  return false
end

---Show the given output in a new scratch buffer.
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
  vim.cmd("vsplit | buffer " .. buf)
  vim.api.nvim_buf_set_name(buf, title)
end

------------------------------------------------------------------
-- Sync runner
------------------------------------------------------------------

---Run a shell command synchronously and return its output.
---@param cmd string[]
---@return string out, string err, integer code
local function run_sync(cmd)
  local obj = vim.system(cmd, { text = true, cwd = cwd }):wait()
  ---@cast obj {stdout:string,stderr:string,code:integer}
  return obj.stdout or "", obj.stderr or "", obj.code
end

------------------------------------------------------------------
-- Terminal buffer
------------------------------------------------------------------

---Run command in a terminal buffer and open it in a split.
---@param cmd string
---@param bang? boolean
local function open_term(cmd, bang)
  term_buf = vim.api.nvim_create_buf(false, true)

  local win = vim.fn.bufwinnr(term_buf)
  if win == -1 then
    vim.cmd("botright split | buffer " .. term_buf)
  else
    vim.cmd(win .. "wincmd w")
  end

  vim.fn.jobstart(cmd, {
    term = true,
    cwd = cwd,
    on_exit = function(_, code)
      ---If bang then dont do anything, let the user handle it.
      if bang then
        return
      end

      local lines = vim.api.nvim_buf_get_lines(term_buf, 0, -1, false)

      ---trim the stderr for empty lines
      lines = vim.tbl_filter(function(s)
        return s ~= ""
      end, lines)

      local stderr = table.concat(lines, "\n")

      if code == 0 then
        notify(stderr, "INFO")
      elseif code == 1 then
        notify(stderr, "ERROR")
      else
        notify(string.format("gh exited with code %d", code), "ERROR")
      end

      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
      end)
    end,
  })
  vim.cmd("startinsert")
end

------------------------------------------------------------------
-- Public
------------------------------------------------------------------

---Set up the :Gh command.
function M.setup()
  if not has_gh then
    vim.api.nvim_create_user_command("Gh", function()
      notify("`gh` not found", "ERROR")
    end, {})
    return
  end

  vim.api.nvim_create_user_command("Gh", function(opts)
    local bang = opts.bang
    local args = vim.split(opts.args or "", "%s+", { trimempty = true })
    if #args == 0 then
      notify("No arguments provided", "WARN")
      return
    end
    local cmd = vim.list_extend({ "gh" }, args)

    ---Handle bangs
    if bang then
      open_term(shellescape(cmd), bang)
      return
    end

    ---Like `--help` or `--version`.
    if is_info(args) then
      local out, err, code = run_sync(cmd)
      if code ~= 0 then
        notify(err ~= "" and err or out, "ERROR")
      elseif out ~= "" then
        show_buffer(out, "gh://" .. opts.args)
      end
      return
    end

    open_term(shellescape(cmd), bang)
  end, { nargs = "*", bang = true })
end

return M
