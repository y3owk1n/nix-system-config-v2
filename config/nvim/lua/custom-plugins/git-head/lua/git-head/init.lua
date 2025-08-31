---@class GitHead
local M = {}

-- ------------------------------------------------------------------
-- Config & state
-- ------------------------------------------------------------------

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

-- Cleanup tracker for orphaned timers
local cleanup_timer = nil

---@type boolean
local did_setup = false

-- ------------------------------------------------------------------
-- low-level helpers
-- ------------------------------------------------------------------

---Build a git command with standard args
---@param args string[]
---@return string[]
local function git_cmd(args)
  return { M.config.git_executable, "-c", "gc.auto=0", unpack(args) }
end

---Run a git command asynchronously with proper error handling
---@param cmd string[]
---@param cwd string
---@param on_done fun(code: integer, stdout: string, stderr?: string)
---@return uv.uv_process_t?
local function spawn(cmd, cwd, on_done)
  local out = {}
  local err = {}
  local stdout = vim.uv.new_pipe()
  local stderr = vim.uv.new_pipe()
  local handle

  handle = vim.uv.spawn(cmd[1], {
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
    if handle then
      handle:close()
    end
    if stdout then
      stdout:close()
    end
    if stderr then
      stderr:close()
    end

    local stdout_str = table.concat(out):gsub("\n+$", "")
    local stderr_str = table.concat(err):gsub("\n+$", "")
    on_done(code, stdout_str, stderr_str)
  end)

  if not handle then
    return nil
  end

  if stdout then
    stdout:read_start(function(_, data)
      if data then
        table.insert(out, data)
      end
    end)
  end

  if stderr then
    stderr:read_start(function(_, data)
      if data then
        table.insert(err, data)
      end
    end)
  end

  -- Timeout handling
  vim.defer_fn(function()
    if handle and handle:is_active() then
      handle:kill("sigterm")
    end
  end, M.config.timeout)

  return handle
end

---Trigger a status line redraw
local function redraw()
  vim.schedule(function()
    vim.cmd.redrawstatus()
  end)
end

---Check if buffer is valid for git tracking
---@param buf integer
---@return boolean
local function is_valid_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  local buftype = vim.bo[buf].buftype
  if buftype ~= "" then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return false
  end

  return true
end

-- ------------------------------------------------------------------
-- data update
-- ------------------------------------------------------------------

---Update HEAD info for a buffer
---@param buf integer
---@param root string
---@return nil
local function update_buf_head(buf, root)
  spawn(git_cmd({ "rev-parse", "HEAD", "--abbrev-ref", "HEAD" }), root, function(code, out, stderr)
    vim.schedule(function()
      if code ~= 0 then
        if M.config.debug then
          vim.notify(string.format("GitHead: git command failed: %s", stderr or "unknown error"), vim.log.levels.DEBUG)
        end
        return
      end

      if not is_valid_buffer(buf) then
        return
      end

      local head, head_name = out:match("^(.-)\n(.*)$")
      if not head then
        return
      end

      local summary = cache[buf]
      if not summary then
        return -- Buffer was disabled while git command was running
      end

      summary.head = head
      summary.head_name = head_name == "HEAD" and head:sub(1, 7) or head_name

      vim.b[buf].githead_summary = {
        head = summary.head,
        head_name = summary.head_name,
      }
      vim.b[buf].githead_summary_string = summary.head_name
      redraw()
    end)
  end)
end

-- ------------------------------------------------------------------
-- repo watcher
-- ------------------------------------------------------------------

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
    r.timer:close()
  end
  repos[repo_path] = nil
end

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
  if not timer then
    return
  end

  repos[repo_path].timer = timer

  timer:start(
    0,
    M.config.poll_interval,
    vim.schedule_wrap(function()
      -- Check if repo still has active buffers
      if not repos[repo_path] or vim.tbl_isempty(repos[repo_path].buffers) then
        unwatch_repo(repo_path)
        return
      end

      vim.uv.fs_stat(head_path, function(stat_err, stat)
        if stat_err or not stat then
          return
        end

        vim.schedule(function()
          if not repos[repo_path] then
            return
          end

          local mtime = stat.mtime.sec
          if mtime ~= repos[repo_path].last_mtime then
            repos[repo_path].last_mtime = mtime

            -- Clean up invalid buffers while updating
            local valid_buffers = {}
            for buf in pairs(repos[repo_path].buffers) do
              if is_valid_buffer(buf) and cache[buf] then
                valid_buffers[buf] = true
                update_buf_head(buf, cache[buf].root)
              end
            end
            repos[repo_path].buffers = valid_buffers
          end
        end)
      end)
    end)
  )
end

---Cleanup orphaned watchers periodically
local function start_cleanup_timer()
  if cleanup_timer then
    return
  end

  cleanup_timer = vim.uv.new_timer()
  if cleanup_timer then
    cleanup_timer:start(
      30000,
      30000,
      vim.schedule_wrap(function()
        for repo_path, repo in pairs(repos) do
          -- Clean up invalid buffers
          local valid_buffers = {}
          for buf in pairs(repo.buffers) do
            if is_valid_buffer(buf) and cache[buf] then
              valid_buffers[buf] = true
            else
              cache[buf] = nil
            end
          end

          if vim.tbl_isempty(valid_buffers) then
            unwatch_repo(repo_path)
          else
            repo.buffers = valid_buffers
          end
        end
      end)
    )
  end
end

-- ------------------------------------------------------------------
-- buffer enable / disable
-- ------------------------------------------------------------------

---Enable Git HEAD tracking for buffer
---@param buf integer
---@return nil
local function enable_buf(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

  if not is_valid_buffer(buf) or cache[buf] then
    return
  end

  local path = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf))
  if not path then
    return
  end

  local dir = vim.fn.fnamemodify(path, ":h")

  spawn(git_cmd({ "rev-parse", "--git-dir", "--show-toplevel" }), dir, function(code, out, stderr)
    vim.schedule(function()
      if code ~= 0 then
        if M.config.debug then
          vim.notify(string.format("GitHead: not in git repo: %s", stderr or "unknown error"), vim.log.levels.DEBUG)
        end
        return
      end

      if not is_valid_buffer(buf) then
        return
      end

      local repo, root = out:match("^(.-)\n(.*)$")
      if not repo or not root then
        return
      end

      -- Convert relative git-dir to absolute path
      if not vim.startswith(repo, "/") then
        repo = vim.fn.fnamemodify(dir .. "/" .. repo, ":p")
      end

      cache[buf] = { repo = repo, root = root }
      vim.b[buf].githead_summary = {}
      vim.b[buf].githead_summary_string = ""

      repos[repo] = repos[repo] or { buffers = {} }
      repos[repo].buffers[buf] = true
      watch_repo(repo)

      update_buf_head(buf, root)
    end)
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

  -- Clear buffer variables
  pcall(function()
    vim.b[buf].githead_summary = nil
    vim.b[buf].githead_summary_string = nil
  end)

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
---@field debug? boolean Enable debug logging. Default: false
M.defaults = {
  git_executable = "git",
  timeout = 3000,
  poll_interval = 1000,
  debug = false,
}

---@param user_config? GitHead.Config
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  -- Start cleanup timer
  start_cleanup_timer()

  -- enable for existing buffers
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if is_valid_buffer(b) then
      enable_buf(b)
    end
  end

  -- auto-enable future buffers
  local gid = vim.api.nvim_create_augroup("GitHead", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = gid,
    callback = function(args)
      enable_buf(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = gid,
    callback = function(args)
      disable_buf(args.buf)
    end,
  })

  -- Cleanup on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = gid,
    callback = function()
      M.cleanup()
    end,
  })

  did_setup = true
end

---Get the root of a Git repo for a buffer
---@param buf? integer
---@return string?
function M.get_root(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return cache[buf] and cache[buf].root
end

---Get the current HEAD info for a buffer
---@param buf? integer
---@return {head: string?, head_name: string?}?
function M.get_head(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local summary = cache[buf]
  if not summary then
    return nil
  end
  return {
    head = summary.head,
    head_name = summary.head_name,
  }
end

---Manually refresh HEAD info for a buffer
---@param buf? integer
function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local summary = cache[buf]
  if summary then
    update_buf_head(buf, summary.root)
  end
end

---Get status information for debugging
---@return table
function M.status()
  return {
    repos = vim.tbl_count(repos),
    cached_buffers = vim.tbl_count(cache),
    repo_details = vim.tbl_map(function(repo)
      return {
        buffer_count = vim.tbl_count(repo.buffers),
        last_mtime = repo.last_mtime,
        has_timer = repo.timer ~= nil,
      }
    end, repos),
  }
end

---Clean up all resources
function M.cleanup()
  -- Stop all repo timers
  for repo_path in pairs(repos) do
    unwatch_repo(repo_path)
  end

  -- Stop cleanup timer
  if cleanup_timer then
    cleanup_timer:stop()
    cleanup_timer:close()
    cleanup_timer = nil
  end

  -- Clear caches
  cache = {}
  repos = {}
end

return M
