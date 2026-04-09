---@class FuzzySearch
local M = {}

---@type boolean
local did_setup = false

-- ------------------------------------------------------------------
-- Private state
-- ------------------------------------------------------------------

---@type string[]|nil
local file_cache = nil

---@type boolean
local loading = false

---@type uv_fs_event_t|nil
local fs_watcher = nil

---@type string|nil
local last_grep_query = nil

---@type table|nil
local last_grep_opts = nil

---@type uv_timer_t|nil
local debounce_timer = nil

local qf_ns = vim.api.nvim_create_namespace("FuzzySearchQF")

-- ------------------------------------------------------------------
-- Private helpers
-- ------------------------------------------------------------------

local function get_cmd()
  return vim.fn.split(vim.fn.getcmdline(), " ")[1]
end

local function is_cmdline_type_find()
  local cmd = get_cmd()
  return cmd == "find" or cmd == "fin"
end

---Build the base rg --files argument list
---@return string[]
local function rg_files_args()
  local args = { "rg", "--files", "--hidden", "--color=never", "--glob=!.git" }
  if not M.config.respect_ignore then
    table.insert(args, "--no-ignore")
  end
  return args
end

---Start watching cwd for file changes and invalidate cache on change
local function start_fs_watch()
  if fs_watcher then
    return
  end

  local watcher = vim.uv.new_fs_event()
  if not watcher then
    return
  end

  watcher:start(vim.fn.getcwd(), { recursive = true }, function(err, _, _)
    if err then
      return
    end
    file_cache = nil
    vim.uv.new_timer():start(300, 0, function()
      if not file_cache and not loading then
        loading = true
        vim.system(rg_files_args(), { text = true }, function(obj)
          file_cache = vim.split(obj.stdout, "\n", { trimempty = true })
          loading = false
        end)
      end
    end)
  end)

  fs_watcher = watcher
end

---Stop fs watcher (called on VimLeave)
local function stop_fs_watch()
  if fs_watcher then
    fs_watcher:stop()
    fs_watcher = nil
  end
end

---Preload files using rg (async). Cache persists across cmdline sessions;
---invalidation is handled by the fs watcher.
local function preload_files()
  if file_cache or loading then
    return
  end
  loading = true
  vim.system(rg_files_args(), { text = true }, function(obj)
    file_cache = vim.split(obj.stdout, "\n", { trimempty = true })
    loading = false
  end)
end

---Fallback sync load used only when async cache isn't ready yet
---@return string[]
local function load_files_sync()
  return vim.fn.systemlist(table.concat(rg_files_args(), " "))
end

---Fuzzy match with optional result cap
---@param items string[]
---@param query string
---@return string[]
local function lua_fuzzy_match(items, query)
  if query == "" or not query then
    return items
  end

  local q = query:lower()
  local results = {}
  local cap = M.config.max_results or math.huge

  for _, v in ipairs(items) do
    if #results >= cap then
      break
    end
    local name = v:lower()
    local pos = 1
    local matched = true
    for i = 1, #q do
      local s, e = name:find(q:sub(i, i), pos, true)
      if not s then
        matched = false
        break
      end
      pos = e + 1
    end
    if matched then
      table.insert(results, v)
    end
  end

  return results
end

---Build rg --grep argument list from config + call-site overrides
---@param query string|string[]
---@param opts? { cwd?: string, flags?: string[] }
---@return string[], string
local function build_grep_args(query, opts)
  opts = opts or {}

  local args = { "rg", "--vimgrep", "--color=never", "--smart-case" }

  if not M.config.respect_ignore then
    table.insert(args, "--no-ignore")
  end

  for _, f in ipairs(M.config.grep_flags or {}) do
    table.insert(args, f)
  end

  for _, f in ipairs(opts.flags or {}) do
    table.insert(args, f)
  end

  local display_query
  if type(query) == "table" then
    display_query = table.concat(query, ", ")
    for _, q in ipairs(query) do
      table.insert(args, "-e")
      table.insert(args, q)
    end
  else
    display_query = query
    table.insert(args, query)
  end

  if opts.cwd then
    table.insert(args, opts.cwd)
  end

  return args, display_query
end

-- ------------------------------------------------------------------
-- Quickfix highlight helpers
-- ------------------------------------------------------------------

---Re-apply grep match highlights on the quickfix buffer.
---@param query string|string[]
local function highlight_qf_grep(query)
  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid == 0 then
    return
  end
  local buf = vim.api.nvim_win_get_buf(qf_winid)

  vim.api.nvim_buf_clear_namespace(buf, qf_ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local patterns = type(query) == "table" and query or { query }

  for lnum, line in ipairs(lines) do
    -- quickfix line format: "filename|row col| text"
    -- find the second "|" to locate where match text begins
    local text_start = line:find("|", 1, true)
    text_start = text_start and line:find("|", text_start + 1, true)
    if text_start then
      local text_offset = text_start
      local text = line:sub(text_offset + 1)

      for _, q in ipairs(patterns) do
        local search = q:lower()
        local haystack = text:lower()
        local s = 1
        while true do
          local ms, me = haystack:find(search, s, true)
          if not ms then
            break
          end
          vim.api.nvim_buf_set_extmark(buf, qf_ns, lnum - 1, text_offset + ms - 1, {
            end_col = text_offset + me,
            hl_group = "Search",
          })
          s = me + 1
        end
      end
    end
  end
end

---Highlight fuzzy-matched characters in a files quickfix buffer.
---@param query string
local function highlight_qf_files(query)
  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid == 0 then
    return
  end
  local buf = vim.api.nvim_win_get_buf(qf_winid)

  vim.api.nvim_buf_clear_namespace(buf, qf_ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local q = query:lower()

  for lnum, line in ipairs(lines) do
    local haystack = line:lower()
    local pos = 1
    for i = 1, #q do
      local c = q:sub(i, i)
      local s, e = haystack:find(c, pos, true)
      if not s then
        break
      end
      vim.api.nvim_buf_set_extmark(buf, qf_ns, lnum - 1, s - 1, {
        end_col = e,
        hl_group = "Search",
      })
      pos = e + 1
    end
  end
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class FuzzySearch.Config
---@field debounce_ms?    number    ms to debounce CmdlineChanged (default 50)
---@field max_files?      number    optional file list cap
---@field max_results?    number    max fuzzy match results returned (default 200)
---@field grep_flags?     string[]  extra rg flags for every grep run
---@field respect_ignore? boolean   honour .gitignore / .rgignore (default true)

M.config = {}

local default_config = {
  debounce_ms = 50,
  max_files = nil,
  max_results = 200,
  grep_flags = {},
  respect_ignore = true,
}

---Run a live grep with rg, stream results into the quickfix list.
---@param query? string|string[]  prompt if omitted; table = multi-pattern
---@param opts?  { cwd?: string, flags?: string[] }
function M.grep(query, opts)
  if not query or (type(query) == "string" and query == "") then
    query = vim.fn.input("Grep > ")
    if query == "" then
      return
    end
  end

  last_grep_query = query
  last_grep_opts = opts

  local args, display_query = build_grep_args(query, opts)

  vim.schedule(function()
    vim.fn.setqflist({}, " ", { title = "Grep: " .. display_query })
    vim.cmd("copen")
  end)

  local result_lines = {}

  vim.system(args, {
    text = true,
    stdout = function(err, data)
      if err or not data then
        return
      end
      local chunk_lines = vim.split(data, "\n", { trimempty = true })
      vim.list_extend(result_lines, chunk_lines)
      vim.schedule(function()
        vim.fn.setqflist({}, "a", {
          lines = chunk_lines,
          efm = "%f:%l:%c:%m",
        })
      end)
    end,
  }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 and #result_lines == 0 then
        vim.notify("FuzzySearch: no results for '" .. display_query .. "'", vim.log.levels.INFO)
        vim.cmd("cclose")
        return
      end
      highlight_qf_grep(query)
    end)
  end)
end

---Re-run the last grep query with the same options.
function M.grep_last()
  if not last_grep_query then
    vim.notify("FuzzySearch: no previous grep", vim.log.levels.WARN)
    return
  end
  M.grep(last_grep_query, last_grep_opts)
end

---Fuzzy-match the file list and populate quickfix (outside of :find).
---@param query? string  prompt if omitted
function M.files(query)
  if not query or query == "" then
    query = vim.fn.input("Files > ")
    if query == "" then
      return
    end
  end

  if not file_cache then
    file_cache = load_files_sync()
  end

  local matches = lua_fuzzy_match(file_cache, query)

  if #matches == 0 then
    vim.notify("FuzzySearch: no files match '" .. query .. "'", vim.log.levels.INFO)
    return
  end

  local qf_items = vim.tbl_map(function(f)
    return { filename = f, lnum = 1, col = 1, text = f }
  end, matches)

  vim.fn.setqflist({}, " ", {
    title = "Files: " .. query,
    items = qf_items,
  })
  vim.cmd("copen")
  highlight_qf_files(query)
end

---Setup the module.
---@param user_config? FuzzySearch.Config
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

  -- findfunc ---------------------------------------------------------
  function _G.FuzzySearchFiles(cmdarg)
    if not file_cache then
      file_cache = load_files_sync()
    end
    return lua_fuzzy_match(file_cache, cmdarg)
  end

  vim.o.findfunc = "v:lua.FuzzySearchFiles"

  -- grepprg / grepformat ---------------------------------------------
  vim.o.grepprg = "rg --vimgrep --color=never --smart-case $*"
  vim.o.grepformat = "%f:%l:%c:%m"

  -- Cmdline behaviour ------------------------------------------------
  local augroup = vim.api.nvim_create_augroup("FuzzySearchCmdline", { clear = true })

  vim.api.nvim_create_autocmd({ "CmdlineChanged", "CmdlineLeave" }, {
    group = augroup,
    callback = function(ev)
      local cmd = get_cmd()
      local function should_enable()
        return is_cmdline_type_find() or cmd == "help" or cmd == "h"
      end

      if ev.event == "CmdlineChanged" and should_enable() then
        if is_cmdline_type_find() then
          preload_files()
        end

        if debounce_timer then
          debounce_timer:stop()
        end
        debounce_timer = vim.uv.new_timer()
        debounce_timer:start(
          M.config.debounce_ms,
          0,
          vim.schedule_wrap(function()
            vim.opt.wildmode = "noselect:lastused,full"
            vim.fn.wildtrigger()
            debounce_timer = nil
          end)
        )
      end

      if ev.event == "CmdlineLeave" then
        vim.opt.wildmode = "full"
        if debounce_timer then
          debounce_timer:stop()
          debounce_timer = nil
        end
      end
    end,
  })

  -- Re-apply grep highlights when returning to an existing quickfix window
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    pattern = "quickfix",
    callback = function()
      if last_grep_query then
        highlight_qf_grep(last_grep_query)
      end
    end,
  })

  -- Kick off background preload + fs watch on startup ----------------
  preload_files()
  start_fs_watch()

  vim.api.nvim_create_autocmd("VimLeave", {
    group = augroup,
    callback = stop_fs_watch,
  })

  did_setup = true
end

-- Debug / utility ----------------------------------------------------

function M.clear()
  file_cache = nil
  loading = false
end

---@return table
function M.status()
  return {
    cached = file_cache ~= nil,
    loading = loading,
    count = file_cache and #file_cache or 0,
    watching = fs_watcher ~= nil,
    last_grep_query = last_grep_query,
  }
end

return M
