---@class BigFile
local M = {}

local did_setup = false
local augroup_id = nil

-- ------------------------------------------------------------------
-- Types
-- ------------------------------------------------------------------

---@class BigFile.Config
---@field enabled? boolean Whether the plugin is enabled
---@field notify? boolean Show notification when big file is detected
---@field size? number File size threshold in bytes (default: 1.5MB)
---@field line_length? number Average line length threshold for detection
---@field features? BigFileFeatures Features to disable/modify for big files
---@field setup? fun(ctx: BigFileContext): nil Custom setup function for big files

---@class BigFileContext
---@field buf number Buffer handle
---@field path string File path
---@field ft string Original filetype
---@field size number File size in bytes
---@field lines number Number of lines in file

---@class BigFileFeatures
---@field syntax boolean
---@field treesitter boolean
---@field lsp boolean
---@field matchparen boolean
---@field foldmethod string
---@field statuscolumn string
---@field conceallevel number
---@field wrap boolean
---@field spell boolean
---@field list boolean
---@field number boolean
---@field relativenumber boolean
---@field cursorline boolean
---@field colorcolumn string

-- ------------------------------------------------------------------
-- Private variables and functions
-- ------------------------------------------------------------------

---@private
---Check if a buffer is valid and loaded
---@param buf number Buffer handle
---@return boolean
local function is_buffer_valid(buf)
  return buf and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf)
end

---@private
---Safely set window options
---@param win number Window handle (0 for current)
---@param opts table Window options to set
local function set_win_options(win, opts)
  if not vim.api.nvim_win_is_valid(win == 0 and vim.api.nvim_get_current_win() or win) then
    return
  end

  for opt, value in pairs(opts) do
    local ok, err = pcall(vim.api.nvim_set_option_value, opt, value, { scope = "local", win = win })
    if not ok then
      vim.notify(string.format("BigFile: Failed to set window option '%s': %s", opt, err), vim.log.levels.WARN)
    end
  end
end

---@private
---Safely set buffer options
---@param buf number Buffer handle
---@param opts table Buffer options to set
local function set_buf_options(buf, opts)
  if not is_buffer_valid(buf) then
    return
  end

  for opt, value in pairs(opts) do
    local ok, err = pcall(vim.api.nvim_set_option_value, opt, value, { buf = buf })
    if not ok then
      vim.notify(string.format("BigFile: Failed to set buffer option '%s': %s", opt, err), vim.log.levels.WARN)
    end
  end
end

---@private
---Disable LSP features for the buffer
---@param buf number Buffer handle
local function disable_lsp(buf)
  if not is_buffer_valid(buf) then
    return
  end

  -- Detach all LSP clients from the buffer
  local clients = vim.lsp.get_clients({ bufnr = buf })
  for _, client in ipairs(clients) do
    pcall(vim.lsp.buf_detach_client, buf, client.id)
  end

  -- Disable LSP-related buffer variables
  vim.b[buf].lsp_attached = false

  -- Disable common LSP-related plugins
  vim.b[buf].coc_enabled = 0
  vim.b[buf].ale_enabled = 0
end
---@param buf number Buffer handle
local function disable_treesitter(buf)
  if not is_buffer_valid(buf) then
    return
  end

  -- Disable built-in vim.treesitter features (Neovim >= 0.9)
  if vim.treesitter and vim.treesitter.stop then
    pcall(vim.treesitter.stop, buf)
  end

  -- Disable built-in treesitter highlighting
  if vim.treesitter.highlighter and vim.treesitter.highlighter.active then
    local highlighter = vim.treesitter.highlighter.active[buf]
    if highlighter then
      pcall(highlighter.destroy, highlighter)
    end
  end

  -- Disable nvim-treesitter plugin if available
  local ok, ts_configs = pcall(require, "nvim-treesitter.configs")
  if ok and ts_configs then
    -- Try the newer API first
    local ok2, ts_utils = pcall(require, "nvim-treesitter.utils")
    if ok2 and ts_utils and ts_utils.disable_all then
      pcall(ts_utils.disable_all, buf)
    else
      -- Fallback to older API
      local ok3, ts_highlight = pcall(require, "nvim-treesitter.highlight")
      if ok3 and ts_highlight and ts_highlight.detach then
        pcall(ts_highlight.detach, buf)
      end
    end
  end

  -- Set buffer variables to prevent treesitter features
  vim.b[buf].ts_highlight = false
  vim.b[buf].ts_indent = false
  vim.b[buf].treesitter_highlight = false

  -- Disable specific treesitter modules via buffer variables
  vim.b[buf].ts_context_commentstring_disabled = true
  vim.b[buf].ts_rainbow_disabled = true
  vim.b[buf].ts_autopairs_disabled = true
end

---@private
---Apply big file optimizations
---@param ctx BigFileContext
local function apply_big_file_optimizations(ctx)
  if not is_buffer_valid(ctx.buf) then
    return
  end

  -- Use custom setup function if provided
  if M.config.setup and type(M.config.setup) == "function" then
    local ok, err = pcall(M.config.setup, ctx)
    if not ok then
      vim.notify(string.format("BigFile: Custom setup function failed: %s", err), vim.log.levels.ERROR)
    end
    return
  end

  -- Default optimizations
  local features = M.config.features or {}

  -- Disable match parentheses
  if features.matchparen and vim.fn.exists(":NoMatchParen") ~= 0 then
    ---@diagnostic disable-next-line: param-type-mismatch
    pcall(vim.cmd, "NoMatchParen")
  end

  -- Set window options
  local win_opts = {}
  if features.foldmethod then
    win_opts.foldmethod = features.foldmethod
  end
  if features.statuscolumn ~= nil then
    win_opts.statuscolumn = features.statuscolumn
  end
  if features.conceallevel ~= nil then
    win_opts.conceallevel = features.conceallevel
  end
  if features.wrap ~= nil then
    win_opts.wrap = features.wrap
  end
  if features.spell ~= nil then
    win_opts.spell = features.spell
  end
  if features.list ~= nil then
    win_opts.list = features.list
  end
  if features.number ~= nil then
    win_opts.number = features.number
  end
  if features.relativenumber ~= nil then
    win_opts.relativenumber = features.relativenumber
  end
  if features.cursorline ~= nil then
    win_opts.cursorline = features.cursorline
  end
  if features.colorcolumn ~= nil then
    win_opts.colorcolumn = features.colorcolumn
  end

  set_win_options(0, win_opts)

  -- Disable various animations and features
  vim.b[ctx.buf].minianimate_disable = true
  vim.b[ctx.buf].miniindentscope_disable = true
  vim.b[ctx.buf].minicursorword_disable = true

  -- Disable treesitter if requested
  if features.treesitter then
    disable_treesitter(ctx.buf)
  end

  -- Disable LSP if requested
  if features.lsp then
    disable_lsp(ctx.buf)
  end

  -- Handle syntax highlighting
  if features.syntax then
    -- Schedule syntax setting to avoid issues with filetype detection
    vim.schedule(function()
      if is_buffer_valid(ctx.buf) then
        set_buf_options(ctx.buf, { syntax = "off" })
      end
    end)
  else
    -- Restore original syntax if we're keeping syntax on
    vim.schedule(function()
      if is_buffer_valid(ctx.buf) and ctx.ft and ctx.ft ~= "" then
        set_buf_options(ctx.buf, { syntax = ctx.ft })
      end
    end)
  end
end

---@private
---Check if file should be treated as big file
---@param path string File path
---@param buf number Buffer handle
---@return boolean is_big_file
---@return number? file_size
---@return number? line_count
local function is_big_file(path, buf)
  if not path or path == "" or not is_buffer_valid(buf) then
    return false
  end

  -- Skip if already detected as bigfile
  local current_ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
  if current_ft == "bigfile" then
    return false
  end

  -- Check if path matches buffer name (avoid processing temporary buffers)
  local buf_name = vim.api.nvim_buf_get_name(buf)
  if path ~= buf_name then
    return false
  end

  -- Get file size
  local bufnr = vim.api.nvim_get_current_buf()
  local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr))
  if not stat then
    return false
  end
  local size = stat.size
  if size <= 0 then
    return false
  end

  -- Check size threshold
  if size > M.config.size then
    return true, size, vim.api.nvim_buf_line_count(buf)
  end

  -- Check line length threshold
  local lines = vim.api.nvim_buf_line_count(buf)
  if lines > 0 then
    local avg_line_length = (size - lines) / lines
    if avg_line_length > M.config.line_length then
      return true, size, lines
    end
  end

  return false, size, lines
end

---@private
---Format file size for display
---@param bytes number File size in bytes
---@return string
local function format_size(bytes)
  local units = { "B", "KB", "MB", "GB" }
  local size = bytes
  local unit_index = 1

  while size >= 1024 and unit_index < #units do
    size = size / 1024
    unit_index = unit_index + 1
  end

  return string.format("%.1f%s", size, units[unit_index])
end

-- ------------------------------------------------------------------
-- Setup Autocmds
-- ------------------------------------------------------------------

local function setup_autocmds()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup_id,
    callback = function(event)
      local buf = event.buf
      local path = vim.api.nvim_buf_get_name(buf)
      local is_big = is_big_file(path, buf)
      if is_big then
        vim.bo[buf].filetype = "bigfile"
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup_id,
    pattern = "bigfile",
    callback = function(event)
      local buf = event.buf
      local path = vim.api.nvim_buf_get_name(buf)

      if not is_buffer_valid(buf) then
        return
      end

      -- Get file info
      local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
      if not stat then
        return
      end

      local size = stat.size
      local lines = vim.api.nvim_buf_line_count(buf)
      local original_ft = vim.filetype.match({ buf = buf }) or ""

      -- Show notification if enabled
      if M.config.notify then
        local relative_path = vim.fn.fnamemodify(path, ":p:~:.")
        local size_str = format_size(size)

        vim.notify(
          string.format(
            "Big file detected: %s (%s, %d lines)\nSome Neovim features have been disabled for better performance.",
            relative_path,
            size_str,
            lines
          ),
          vim.log.levels.WARN,
          { title = "BigFile Plugin" }
        )
      end

      -- Create context for setup function
      local ctx = {
        buf = buf,
        path = path,
        ft = original_ft,
        size = size,
        lines = lines,
      }

      -- Apply optimizations in buffer context
      vim.api.nvim_buf_call(buf, function()
        apply_big_file_optimizations(ctx)
      end)
    end,
  })
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class BigFile.Config
M.config = {}

---@type BigFile.Config
local default_config = {
  enabled = true,
  notify = true,
  size = 3 * 1024 * 1024, -- 1.5MB
  line_length = 10000, -- average line length threshold
  features = {
    syntax = true, -- disable syntax highlighting
    treesitter = true, -- disable treesitter (both built-in and nvim-treesitter)
    lsp = true, -- disable LSP features
    matchparen = true, -- disable match parentheses
    foldmethod = "manual", -- set fold method to manual
    statuscolumn = "", -- clear status column
    conceallevel = 0, -- disable concealing
    wrap = false, -- disable line wrapping
    spell = false, -- disable spell checking
    list = false, -- disable list mode
    number = false, -- disable line numbers
    relativenumber = false, -- disable relative line numbers
    cursorline = false, -- disable cursor line highlighting
    colorcolumn = "", -- clear color column
  },
  setup = nil, -- Custom setup function (overrides default behavior if provided)
}

---Setup the bigfile plugin
---@param user_config? BigFile.Config
function M.setup(user_config)
  if did_setup then
    vim.notify("BigFile: Plugin already set up", vim.log.levels.WARN)
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

  if not M.config.enabled then
    return
  end

  -- Create augroup
  augroup_id = vim.api.nvim_create_augroup("bigfile_plugin", { clear = true })

  -- Set up autocmd for when bigfile filetype is detected
  setup_autocmds()

  did_setup = true
end

---Manually apply big file optimizations to current buffer
function M.optimize_current_buffer()
  if not did_setup then
    vim.notify("BigFile: Plugin not set up", vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if not is_buffer_valid(buf) then
    vim.notify("BigFile: Current buffer is not valid", vim.log.levels.ERROR)
    return
  end

  local size = vim.fn.getfsize(path)
  local lines = vim.api.nvim_buf_line_count(buf)
  local original_ft = vim.api.nvim_get_option_value("filetype", { buf = buf })

  local ctx = {
    buf = buf,
    path = path,
    ft = original_ft,
    size = size,
    lines = lines,
  }

  apply_big_file_optimizations(ctx)
  vim.notify("BigFile optimizations applied to current buffer", vim.log.levels.INFO)
end

---Disable the plugin (removes autocmds)
function M.disable()
  if augroup_id then
    vim.api.nvim_del_augroup_by_id(augroup_id)
    augroup_id = nil
  end
  M.config.enabled = false
  vim.notify("BigFile plugin disabled", vim.log.levels.INFO)
end

return M
