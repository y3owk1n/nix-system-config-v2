---@class Lazygit
local M = {}

-- ------------------------------------------------------------------
-- State management
-- ------------------------------------------------------------------

---@type boolean
local did_setup = false

local state = {
  term_buf = nil,
  win_id = nil,
  job_id = nil,
}

-- ------------------------------------------------------------------
-- Private helpers
-- ------------------------------------------------------------------

---Check if lazygit is available in PATH
---@return boolean
local function is_lazygit_available()
  return vim.fn.executable("lazygit") == 1
end

---Get window configuration based on user settings
---@param config table
---@return table
local function get_window_config(config)
  local width = math.floor(vim.o.columns * config.width_ratio)
  local height = math.floor(vim.o.lines * config.height_ratio)

  return {
    relative = config.relative,
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = config.border,
  }
end

---Clean up terminal state
local function cleanup_terminal()
  if state.job_id then
    vim.fn.jobstop(state.job_id)
    state.job_id = nil
  end

  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    vim.api.nvim_win_close(state.win_id, true)
    state.win_id = nil
  end

  if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
    vim.api.nvim_buf_delete(state.term_buf, { force = true })
    state.term_buf = nil
  end
end

---Set up buffer options and keymaps
---@param buf number
---@param config table
local function setup_buffer(buf, config)
  -- Buffer options
  vim.api.nvim_set_option_value("filetype", "lazygit", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  -- Set up keymaps if enabled
  if config.close_on_exit then
    vim.api.nvim_buf_set_keymap(
      buf,
      "t",
      "<Esc>",
      "<C-\\><C-n>:lua require('lazygit').close()<CR>",
      { noremap = true, silent = true }
    )
  end

  -- Custom keymaps
  for key, cmd in pairs(config.keymaps) do
    vim.api.nvim_buf_set_keymap(buf, "t", key, cmd, { noremap = true, silent = true })
  end
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class Lazygit.Config
local default_config = {
  width_ratio = 0.8, -- Window width as ratio of editor width
  height_ratio = 0.8, -- Window height as ratio of editor height
  border = "rounded", -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
  relative = "editor", -- Window relative positioning
  close_on_exit = true, -- Close window when lazygit exits
  start_insert = true, -- Start in insert mode
  working_directory = nil, -- Custom working directory (nil = current buffer's directory)
  on_open = nil, -- Callback function when lazygit opens
  on_close = nil, -- Callback function when lazygit closes
  keymaps = {}, -- Custom terminal keymaps
}

---@type Lazygit.Config
M.config = {}

---Setup the plugin with user configuration
---@param user_config? Lazygit.Config
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

  did_setup = true
end

---Check if lazygit terminal is currently open
---@return boolean
function M.is_open()
  return state.term_buf ~= nil and vim.api.nvim_buf_is_valid(state.term_buf)
end

---Close lazygit terminal
function M.close()
  if M.config.on_close then
    M.config.on_close()
  end

  cleanup_terminal()
end

---Open lazygit in a floating terminal
---@param opts? table Optional configuration overrides
function M.open(opts)
  -- Check if lazygit is available
  if not is_lazygit_available() then
    vim.notify("lazygit is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  -- Merge options with config
  local config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Determine working directory
  local cwd = config.working_directory
  if not cwd then
    -- Use current buffer's directory or vim's cwd
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file ~= "" then
      cwd = vim.fn.fnamemodify(current_file, ":h")
    else
      cwd = vim.fn.getcwd()
    end
  end

  -- Create buffer
  state.term_buf = vim.api.nvim_create_buf(false, true)
  if not state.term_buf then
    vim.notify("Failed to create terminal buffer", vim.log.levels.ERROR)
    return
  end

  -- Create floating window
  local win_config = get_window_config(config)
  state.win_id = vim.api.nvim_open_win(state.term_buf, true, win_config)
  if not state.win_id then
    vim.notify("Failed to create floating window", vim.log.levels.ERROR)
    cleanup_terminal()
    return
  end

  -- Setup buffer
  setup_buffer(state.term_buf, config)

  -- Start lazygit
  state.job_id = vim.fn.jobstart({ "lazygit" }, {
    term = true,
    cwd = cwd,
    on_exit = function()
      vim.schedule(function()
        if config.close_on_exit then
          M.close()
        end
      end)
    end,
  })

  if state.job_id <= 0 then
    vim.notify("Failed to start lazygit", vim.log.levels.ERROR)
    cleanup_terminal()
    return
  end

  -- Enter insert mode if configured
  if config.start_insert then
    vim.cmd("startinsert")
  end

  -- Call on_open callback
  if config.on_open then
    config.on_open()
  end
end

---Toggle lazygit terminal (open if closed, close if open)
---@param opts? table Optional configuration overrides
function M.toggle(opts)
  if M.is_open() then
    M.close()
  else
    M.open(opts)
  end
end

---Focus the lazygit window if it's open
function M.focus()
  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    vim.api.nvim_set_current_win(state.win_id)
    if M.config.start_insert then
      vim.cmd("startinsert")
    end
    return true
  end
  return false
end

return M
