local M = {}

---@type boolean
local did_setup = false

-- ------------------------------------------------------------------
-- States & Caches
-- ------------------------------------------------------------------

---@class MiniFilesGit.State
---@field git_status_cache table<string, MiniFilesGit.CacheEntry>
---@field ns_mini_files number|nil
---@field autocmd_group number|nil
---@field is_enabled boolean

---@class MiniFilesGit.CacheEntry
---@field time number
---@field status_map table<string, string>
---@field is_ready boolean

---@type MiniFilesGit.State
local state = {
  git_status_cache = {},
  ns_mini_files = nil,
  autocmd_group = nil,
  is_enabled = false,
}

---@class MiniFilesGit.PrefetchState
---@field active_prefetches table<string, boolean>
---@field pending_buffers table<string, table<number>>

---Track pre-fetch operations
---@type MiniFilesGit.PrefetchState
local prefetch_state = {
  active_prefetches = {},
  pending_buffers = {},
}

local Git = {}

local Mini = {}

-- ------------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------------

---Log a message with a level
---@param level string
---@param msg string
---@param ... any
---@return nil
local function log(level, msg, ...)
  if not M.config.debug and level == "debug" then
    return
  end
  local formatted = string.format("[mini-files-git] " .. msg, ...)
  vim.notify(formatted, vim.log.levels[string.upper(level)])
end

---Validate dependencies
---@return boolean ok True if dependencies are valid
---@return table? validated_mini_files mini.files module if ok
local function check_dependencies()
  local ok, mini_files = pcall(require, "mini.files")
  if not ok then
    log("error", "mini.files not found. Please install mini.files plugin.")
    return false
  end

  -- Check if git is available
  local git_available = vim.fn.executable("git") == 1
  if not git_available then
    log("warn", "git executable not found in PATH")
    return false
  end

  return true, mini_files
end

---Check if a path is a symlink
---@param path string
---@return boolean
local function is_symlink(path)
  if not path or path == "" then
    return false
  end

  local stat = vim.uv.fs_lstat(path)
  return stat and stat.type == "link" or false
end

---Escape a string to be used in a Lua pattern
---@param str string
---@return string
local function escape_pattern(str)
  if not str then
    return ""
  end
  local espaced_str = str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  return espaced_str
end

---Normalize path in a cross-platform way
---@param path string
---@return string
local function normalize_path(path)
  if vim.fn.has("win32") == 1 then
    local normalized = path:gsub("\\", "/")
    return normalized
  end
  return path
end

---Get git status symbol and highlight group for a given status
---@param status string
---@param is_symlink_file boolean
---@return string symbol
---@return string hl_group
local function get_status_symbol(status, is_symlink_file)
  local status_map = {
    [" M"] = { symbol = "✹", hl_group = "MiniDiffSignChange" }, -- Modified in working directory
    ["M "] = { symbol = "•", hl_group = "MiniDiffSignChange" }, -- Modified in index
    ["MM"] = { symbol = "≠", hl_group = "MiniDiffSignChange" }, -- Modified in both
    ["A "] = { symbol = "+", hl_group = "MiniDiffSignAdd" }, -- Added to staging
    ["AA"] = { symbol = "≈", hl_group = "MiniDiffSignAdd" }, -- Added in both
    ["D "] = { symbol = "-", hl_group = "MiniDiffSignDelete" }, -- Deleted from staging
    ["AM"] = { symbol = "⊕", hl_group = "MiniDiffSignChange" }, -- Added in WT, modified in index
    ["AD"] = { symbol = "-•", hl_group = "MiniDiffSignChange" }, -- Added in index, deleted in WT
    ["R "] = { symbol = "→", hl_group = "MiniDiffSignChange" }, -- Renamed in index
    ["U "] = { symbol = "‖", hl_group = "MiniDiffSignChange" }, -- Unmerged path
    ["UU"] = { symbol = "⇄", hl_group = "MiniDiffSignAdd" }, -- Unmerged file
    ["UA"] = { symbol = "⊕", hl_group = "MiniDiffSignAdd" }, -- Unmerged and added in WT
    ["??"] = { symbol = "?", hl_group = "MiniDiffSignDelete" }, -- Untracked
    ["!!"] = { symbol = "!", hl_group = "MiniDiffSignChange" }, -- Ignored
  }

  local result = status_map[status]
  if not result then
    log("debug", "Unknown git status: %s", status)
    return "?", "NonText"
  end

  local symbol = result.symbol
  local hl_group = result.hl_group

  -- Add symlink indicator
  if is_symlink_file then
    symbol = "↩" .. symbol
    hl_group = "MiniDiffSignDelete" -- Override for symlinks
  end

  return symbol, hl_group
end

---Clear git status cache
local function clear_cache()
  state.git_status_cache = {}
  log("debug", "Git status cache cleared")
end

-- ------------------------------------------------------------------
-- Git operations
-- ------------------------------------------------------------------

---Fetch git status for a given directory
---@param cwd string
---@param callback function
function Git.fetch_status(cwd, callback)
  if not cwd then
    log("warn", "No working directory provided")
    callback(nil)
    return
  end

  local git_root = vim.fs.root(cwd, ".git")
  if not git_root then
    log("debug", "Not in a git repository: %s", cwd)
    callback(nil)
    return
  end

  local args = { "git", "status", "--porcelain" }
  if M.config.show_ignored then
    table.insert(args, "--ignored")
  end

  local function on_exit(result)
    vim.schedule(function()
      if result.code == 0 then
        log("debug", "Git status fetched successfully for %s", cwd)
        callback(result.stdout)
      else
        log("warn", "Git command failed with code %d: %s", result.code, result.stderr)
        callback(nil)
      end
    end)
  end

  vim.system(args, {
    text = true,
    cwd = git_root,
    timeout = 5000, -- 5 second timeout
  }, on_exit)
end

---Parse git status output
---@param content string
---@return table<string, string>
function Git.parse_status(content)
  if not content or content == "" then
    return {}
  end

  local git_status_map = {}

  for line in content:gmatch("[^\r\n]+") do
    local status, file_path = line:match("^(..)%s+(.*)")
    if status and file_path then
      -- Handle quoted filenames (git quotes filenames with special characters)
      if file_path:match('^".*"$') then
        file_path = file_path:sub(2, -2):gsub('\\"', '"'):gsub("\\\\", "\\")
      end

      -- Normalize path separators
      file_path = normalize_path(file_path)

      -- Create entries for file and all parent directories
      local parts = {}
      for part in file_path:gmatch("[^/]+") do
        table.insert(parts, part)
      end

      local current_path = ""
      for i, part in ipairs(parts) do
        current_path = current_path == "" and part or current_path .. "/" .. part

        if i == #parts then
          -- File entry
          git_status_map[current_path] = status
        else
          -- Directory entry - only add if not already present
          if not git_status_map[current_path] then
            git_status_map[current_path] = status
          end
        end
      end
    end
  end

  return git_status_map
end

---Pre-fetch git status for common directories
---@param cwd string
function Git.prefetch_status(cwd)
  if not cwd or prefetch_state.active_prefetches[cwd] then
    return
  end

  prefetch_state.active_prefetches[cwd] = true

  Git.fetch_status(cwd, function(content)
    prefetch_state.active_prefetches[cwd] = nil

    if content then
      local git_status_map = Git.parse_status(content)
      local current_time = vim.uv.hrtime() / 1e6

      local git_root = vim.fs.root(cwd, ".git")
      if git_root then
        state.git_status_cache[git_root] = {
          time = current_time,
          status_map = git_status_map,
          is_ready = true, -- Mark as ready for immediate use
        }

        -- Process any pending buffers for this directory
        local pending = prefetch_state.pending_buffers[git_root]
        if pending then
          for _, buf_id in ipairs(pending) do
            if vim.api.nvim_buf_is_valid(buf_id) then
              Mini.update_mini_files_display(buf_id, git_status_map)
            end
          end
          prefetch_state.pending_buffers[git_root] = nil
        end
      end
    end
  end)
end

---Update git status for a given buffer
---@param buf_id number
function Git.update_status(buf_id)
  if not state.is_enabled then
    return
  end

  local cwd = vim.uv.cwd()
  if not cwd then
    log("warn", "Could not determine current working directory")
    return
  end

  local git_root = vim.fs.root(cwd, ".git")
  if not git_root then
    log("debug", "Not in a git repository in `update_git_status`")
    return
  end

  -- Check if we have ready cache data
  local cache_entry = state.git_status_cache[git_root]
  if cache_entry and cache_entry.is_ready then
    -- Use cached data immediately (synchronous display)
    log("debug", "Using ready cached git status for %s", git_root)
    Mini.update_mini_files_display(buf_id, cache_entry.status_map)

    -- Optionally refresh in background if cache is stale
    local current_time = vim.uv.hrtime() / 1e6
    if (current_time - cache_entry.time) >= M.config.cache_timeout then
      vim.defer_fn(function()
        Git.fetch_status(cwd, function(content)
          if content then
            local git_status_map = Git.parse_status(content)
            state.git_status_cache[git_root] = {
              time = vim.uv.hrtime() / 1e6,
              status_map = git_status_map,
              is_ready = true,
            }
            Mini.update_mini_files_display(buf_id, git_status_map)
          end
        end)
      end, 100) -- Small delay to avoid blocking
    end
    return
  end

  -- If cache not ready, queue the buffer and fetch if needed
  if not cache_entry then
    if not prefetch_state.pending_buffers[git_root] then
      prefetch_state.pending_buffers[git_root] = {}
    end
    table.insert(prefetch_state.pending_buffers[git_root], buf_id)

    -- Start pre-fetch if not already running
    if not prefetch_state.active_prefetches[cwd] then
      Git.prefetch_status(cwd)
    end
    return
  end

  -- Fallback to original async behavior for edge cases
  local current_time = vim.uv.hrtime() / 1e6
  if (current_time - cache_entry.time) < M.config.cache_timeout then
    log("debug", "Using cached git status for %s", git_root)
    Mini.update_mini_files_display(buf_id, cache_entry.status_map)
  else
    log("debug", "Fetching fresh git status for %s", git_root)
    Git.fetch_status(cwd, function(content)
      if content then
        local git_status_map = Git.parse_status(content)
        state.git_status_cache[git_root] = {
          time = current_time,
          status_map = git_status_map,
          is_ready = true,
        }
        Mini.update_mini_files_display(buf_id, git_status_map)
      end
    end)
  end
end

-- ------------------------------------------------------------------
-- Mini.files
-- ------------------------------------------------------------------

---Update mini.files display for a given buffer
---@param buf_id number
---@param git_status_map table<string, string>
function Mini.update_mini_files_display(buf_id, git_status_map)
  if not buf_id or not vim.api.nvim_buf_is_valid(buf_id) then
    log("warn", "Invalid buffer ID: %s", buf_id)
    return
  end

  vim.schedule(function()
    -- Clear existing extmarks
    vim.api.nvim_buf_clear_namespace(buf_id, state.ns_mini_files, 0, -1)

    local ok, mini_files = pcall(require, "mini.files")
    if not ok then
      log("error", "Failed to require mini.files")
      return
    end

    local nlines = vim.api.nvim_buf_line_count(buf_id)
    local git_root = vim.fs.root(buf_id, ".git")

    if not git_root then
      log("debug", "No git root found for buffer %d", buf_id)
      return
    end

    local escaped_root = normalize_path(escape_pattern(git_root))

    for i = 1, nlines do
      local entry = mini_files.get_fs_entry(buf_id, i)
      if not entry then
        break
      end

      local relative_path = normalize_path(entry.path):gsub("^" .. escaped_root .. "/", "")
      local status = git_status_map[relative_path]

      if status then
        local is_symlink_file = is_symlink(entry.path)
        local symbol, hl_group = get_status_symbol(status, is_symlink_file)

        local ok_extmark, err = pcall(vim.api.nvim_buf_set_extmark, buf_id, state.ns_mini_files, i - 1, 0, {
          sign_text = symbol,
          sign_hl_group = hl_group,
          priority = 2,
        })

        if not ok_extmark then
          log("warn", "Failed to set extmark: %s", err)
        end
      end
    end
  end)
end

-- ------------------------------------------------------------------
-- Autocmds
-- ------------------------------------------------------------------

-- Setup autocmds
local function setup_autocmds()
  if state.autocmd_group then
    vim.api.nvim_del_augroup_by_id(state.autocmd_group)
  end

  state.autocmd_group = vim.api.nvim_create_augroup("MiniFilesGit", { clear = true })

  -- Update git status when mini.files opens (with immediate display attempt)
  vim.api.nvim_create_autocmd("User", {
    group = state.autocmd_group,
    pattern = "MiniFilesExplorerOpen",
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()

      -- Try immediate display first
      local cwd = vim.uv.cwd()
      local git_root = cwd and vim.fs.root(cwd, ".git")

      if git_root and state.git_status_cache[git_root] and state.git_status_cache[git_root].is_ready then
        -- Immediate synchronous display
        Mini.update_mini_files_display(bufnr, state.git_status_cache[git_root].status_map)
      else
        -- Fallback to async with pre-fetch
        Git.update_status(bufnr)
      end
    end,
    desc = "Update git status when mini.files opens with immediate display",
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    group = state.autocmd_group,
    callback = function()
      local new_cwd = vim.fn.getcwd()
      if new_cwd then
        Git.prefetch_status(new_cwd)
      end
    end,
    desc = "Pre-fetch git status on directory change",
  })

  -- Clear cache when mini.files closes
  vim.api.nvim_create_autocmd("User", {
    group = state.autocmd_group,
    pattern = "MiniFilesExplorerClose",
    callback = clear_cache,
    desc = "Clear git status cache when mini.files closes",
  })

  -- Update display when buffer updates
  vim.api.nvim_create_autocmd("User", {
    group = state.autocmd_group,
    pattern = "MiniFilesBufferUpdate",
    callback = function(args)
      local bufnr = args.data and args.data.buf_id
      if bufnr then
        -- Small delay to ensure the buffer is fully updated
        vim.defer_fn(function()
          Git.update_status(bufnr)
        end, 10)
      end
    end,
    desc = "Update git status when mini.files buffer updates",
  })
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class MiniFilesGit.Config
---@field cache_timeout? number
---@field auto_enable? boolean
---@field show_ignored? boolean
---@field use_icons? boolean
---@field debug? boolean

---@type MiniFilesGit.Config
local default_config = {
  cache_timeout = 2000, -- milliseconds
  auto_enable = true,
  show_ignored = false,
  use_icons = true,
  debug = false,
}

---@type MiniFilesGit.Config
M.config = {}

---@param user_config? MiniFilesGit.Config
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

  -- Validate dependencies
  local deps_ok = check_dependencies()
  if not deps_ok then
    return false
  end

  -- Initialize namespace
  state.ns_mini_files = vim.api.nvim_create_namespace("mini_files_git")

  -- Pre-fetch current directory on setup
  local current_cwd = vim.uv.cwd()
  if current_cwd then
    Git.prefetch_status(current_cwd)
  end

  -- Setup autocmds if auto_enable is true
  if M.config.auto_enable then
    M.enable()
  end

  log("debug", "Mini files git status initialized")

  did_setup = true
end

---Enable the plugin
function M.enable()
  if state.is_enabled then
    log("debug", "Already enabled")
    return
  end

  setup_autocmds()
  state.is_enabled = true
  log("debug", "Git status integration enabled")
end

---Disable the plugin
function M.disable()
  if not state.is_enabled then
    log("debug", "Already disabled")
    return
  end

  if state.autocmd_group then
    vim.api.nvim_del_augroup_by_id(state.autocmd_group)
    state.autocmd_group = nil
  end

  clear_cache()
  state.is_enabled = false
  log("info", "Git status integration disabled")
end

---Toggle the plugin
function M.toggle()
  if state.is_enabled then
    M.disable()
  else
    M.enable()
  end
end

---Refresh the plugin
function M.refresh()
  clear_cache()
  local bufnr = vim.api.nvim_get_current_buf()
  Git.update_status(bufnr)
  log("info", "Git status refreshed")
end

---Get the cached stats
function M.get_cache_stats()
  local count = 0
  local oldest_time = math.huge
  local newest_time = 0

  for _, entry in pairs(state.git_status_cache) do
    count = count + 1
    oldest_time = math.min(oldest_time, entry.time)
    newest_time = math.max(newest_time, entry.time)
  end

  return {
    entries = count,
    oldest_age = count > 0 and (vim.uv.hrtime() / 1e6 - oldest_time) or 0,
    newest_age = count > 0 and (vim.uv.hrtime() / 1e6 - newest_time) or 0,
  }
end

return M
