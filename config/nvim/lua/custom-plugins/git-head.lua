---@class GitHead
local M = {}

-- ------------------------------------------------------------------
-- Config & state
-- ------------------------------------------------------------------

---@type string
local cwd

---Stores info about a Git repo being watched
---@class GitHead.Repo
---@field buffers table<integer, boolean> Buffers associated with this repo
---@field last_head string? Last known HEAD SHA
---@field last_mtime integer? Last modification time of HEAD
---@field timer uv.uv_timer_t? Watch timer

---Keyed by git-dir absolute path
---@type table<string, GitHead.Repo>
local repos = {}

---Per-buffer Git state cache
---@class GitHead.BufCache
---@field repo string Repo path (from `--git-dir`)
---@field root string Repo root (from `--show-toplevel`)
---@field head? string Current HEAD commit hash
---@field head_name? string Branch name or abbreviated commit

---@type table<integer, GitHead.BufCache>
local cache = {}

-- ------------------------------------------------------------------
-- low-level helpers
-- ------------------------------------------------------------------

---Ensure current working directory is set
local function ensure_cwd()
  if cwd then
    return
  end
  cwd = vim.fn.expand("%:p:h")
  if not vim.uv.fs_stat(cwd .. "/.git") then
    cwd = vim.fn.getcwd()
  end
end

---Build a git command with standard args
---@param args string[]
---@return string[]
local function git_cmd(args)
  return { M.config.git_executable, "-c", "gc.auto=0", unpack(args) }
end

---Run a git command asynchronously
---@param cmd string[]
---@param _cwd string
---@param on_done fun(code: integer, stdout: string)
---@return nil
local function spawn(cmd, _cwd, on_done)
  local out = {}
  local stdout = vim.uv.new_pipe()
  local handle
  handle = vim.uv.spawn(cmd[1], {
    args = vim.list_slice(cmd, 2),
    cwd = _cwd,
    stdio = { nil, stdout, nil },
    env = nil,
    uid = nil,
    gid = nil,
    verbatim = nil,
    detached = nil,
    hide = nil,
  }, function(code)
    handle:close()
    if stdout then
      stdout:close()
    end
    on_done(code, table.concat(out):gsub("\n+$", ""))
  end)

  if stdout then
    stdout:read_start(function(_, data)
      if data then
        table.insert(out, data)
      end
    end)
  end

  vim.defer_fn(function()
    if handle and handle:is_active() then
      handle:kill("sigterm")
    end
  end, M.config.timeout)
end

---Trigger a status line redraw
local function redraw()
  vim.schedule(function()
    vim.cmd("redrawstatus")
  end)
end

-- ------------------------------------------------------------------
-- data update
-- ------------------------------------------------------------------

---Update HEAD info for a buffer
---@param buf integer
---@param root string
---@return nil
local function update_buf_head(buf, root)
  spawn(git_cmd({ "rev-parse", "HEAD", "--abbrev-ref", "HEAD" }), root, function(code, out)
    if code ~= 0 then
      return
    end
    local head, head_name = out:match("^(.-)\n(.*)$")
    if not head then
      return
    end

    local summary = cache[buf]
    summary.head, summary.head_name = head, head_name == "HEAD" and head:sub(1, 7) or head_name

    vim.b[buf].githead_summary = {
      head = summary.head,
      head_name = summary.head_name,
    }
    vim.b[buf].githead_summary_string = summary.head_name
    redraw()
  end)
end

-- ------------------------------------------------------------------
-- repo watcher
-- ------------------------------------------------------------------

---Start watching HEAD file of a Git repo
---@param repo_path string
---@return nil
local function watch_repo(repo_path)
  -- Initialize repos table if not already present
  if not repos[repo_path] then
    repos[repo_path] = {
      buffers = {},
      last_head = nil,
      last_mtime = nil,
    }
  end

  if repos[repo_path].timer then
    return
  end

  local head_path = repo_path .. "/HEAD"
  local timer = vim.uv.new_timer()
  repos[repo_path].timer = timer

  if timer then
    timer:start(
      0,
      M.config.poll_interval,
      vim.schedule_wrap(function()
        vim.uv.fs_stat(head_path, function(stat_err, stat)
          if stat_err or not stat then
            return
          end

          local mtime = stat.mtime.sec
          if mtime ~= repos[repo_path].last_mtime then
            repos[repo_path].last_mtime = mtime

            for buf in pairs(repos[repo_path].buffers) do
              if cache[buf] then
                update_buf_head(buf, cache[buf].root)
              end
            end
          end
        end)
      end)
    )
  end
end

---Stop watching a Git repo
---@param repo_path string
---@return nil
local function unwatch_repo(repo_path)
  local r = repos[repo_path]
  if not r then
    return
  end
  if r.timer then
    r.timer:stop()
  end
  repos[repo_path] = nil
end

-- ------------------------------------------------------------------
-- buffer enable / disable
-- ------------------------------------------------------------------

---Enable Git HEAD tracking for buffer
---@param buf integer
---@return nil
local function enable_buf(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if cache[buf] then
    return
  end

  local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf))
  if not (path and vim.fn.filereadable(path) == 1) then
    return
  end

  ensure_cwd()

  spawn(git_cmd({ "rev-parse", "--git-dir", "--show-toplevel" }), cwd, function(code, out)
    if code ~= 0 then
      return
    end
    local repo, root = out:match("^(.-)\n(.*)$")
    if not repo then
      return
    end

    cache[buf] = { repo = repo, root = root }
    vim.b[buf].githead_summary = {}
    vim.b[buf].githead_summary_string = ""

    repos[repo] = repos[repo] or { buffers = {} }
    repos[repo].buffers[buf] = true
    watch_repo(repo)

    update_buf_head(buf, root)
  end)
end

---Disable Git HEAD tracking for buffer
---@param buf integer
---@return nil
local function disable_buf(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local summary = cache[buf]
  if not summary then
    return
  end

  local repo = summary.repo
  cache[buf] = nil
  vim.b[buf].githead_summary = nil
  vim.b[buf].githead_summary_string = nil

  if repos[repo] then
    repos[repo].buffers[buf] = nil
    if vim.tbl_isempty(repos[repo].buffers) then
      unwatch_repo(repo)
    end
  end
end

-- ------------------------------------------------------------------
-- public
-- ------------------------------------------------------------------

---@type GitHead.Config
M.config = {}

---@class GitHead.Config
---@field git_executable? string Default: "git"
---@field timeout? integer Job timeout in ms. Default: 3000
---@field poll_interval? integer Poll interval in ms. Default: 1000
M.defaults = { git_executable = "git", timeout = 3000, poll_interval = 1000 }

---@param user_config? GitHead.Config
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  -- enable for existing buffers
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" then
      enable_buf(b)
    end
  end

  -- auto-enable future buffers
  local gid = vim.api.nvim_create_augroup("GitHead", { clear = true })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = gid,
    pattern = "*",
    callback = function(args)
      enable_buf(args.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = gid,
    pattern = "*",
    callback = function(args)
      disable_buf(args.buf)
    end,
  })
end

return M
