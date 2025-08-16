---@class MarkdownUtils
local M = {}

-- ------------------------------------------------------------------
-- Private helpers
-- ------------------------------------------------------------------

---Get current buffer and cursor information
---@return number bufnr, number win, number row, number col
local function get_cursor_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  return bufnr, win, row - 1, col -- Convert to 0-based indexing
end

---Get line content safely
---@param bufnr number
---@param row number
---@return string
local function get_line(bufnr, row)
  local lines = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  return lines[1] or ""
end

---Check if current buffer is markdown
---@return boolean
local function is_markdown_buffer()
  local ft = vim.bo.filetype
  return ft == "markdown" or ft == "md"
end

---Extract indentation from a line
---@param line string
---@return string
local function get_indent(line)
  return line:match("^(%s*)") or ""
end

---Check if line contains a checkbox pattern
---@param line string
---@return boolean, string|nil
local function find_checkbox(line)
  -- Match various checkbox patterns: [ ], [x], [X], [-]
  local patterns = {
    "(%[ %])", -- [ ]
    "(%[x%])", -- [x]
    "(%[X%])", -- [X]
    "(%[%-])", -- [-]
  }

  for _, pattern in ipairs(patterns) do
    local match = line:match(pattern)
    if match then
      return true, match
    end
  end
  return false, nil
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class MarkdownUtils.Config
---@field auto_insert_mode? boolean Enter insert mode after inserting checkbox
---@field checkbox_style? string Style of checkbox to insert ("- [ ]" or "* [ ]")
---@field check_filetype? boolean Only work in markdown files
M.defaults = {
  auto_insert_mode = true,
  checkbox_style = "- [ ]",
  check_filetype = true,
}

---@type MarkdownUtils.Config
M.config = {}

---Setup the plugin with user configuration
---@param user_config? MarkdownUtils.Config
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

---Toggle markdown checkbox on current line
function M.toggle_markdown_checkbox()
  if M.config.check_filetype and not is_markdown_buffer() then
    vim.notify("Not in a markdown buffer", vim.log.levels.WARN)
    return
  end

  local bufnr, _, row = get_cursor_info()
  local line = get_line(bufnr, row)

  local has_checkbox, current_checkbox = find_checkbox(line)

  if not has_checkbox then
    vim.notify("No checkbox found on current line", vim.log.levels.INFO)
    return
  end

  local new_line
  if current_checkbox == "[ ]" then
    new_line = line:gsub("%[ %]", "[x]", 1)
  elseif current_checkbox == "[x]" or current_checkbox == "[X]" then
    new_line = line:gsub("%[%w%]", "[ ]", 1)
  elseif current_checkbox == "[-]" then
    new_line = line:gsub("%[%-%]", "[x]", 1)
  end

  if new_line and new_line ~= line then
    vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { new_line })
  end
end

---Insert markdown checkbox on current line at cursor position
function M.insert_markdown_checkbox()
  if M.config.check_filetype and not is_markdown_buffer() then
    vim.notify("Not in a markdown buffer", vim.log.levels.WARN)
    return
  end

  local bufnr, win, row, col = get_cursor_info()
  local line = get_line(bufnr, row)

  local checkbox_text = M.config.checkbox_style .. " "
  local new_line = line:sub(1, col) .. checkbox_text .. line:sub(col + 1)

  vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { new_line })

  -- Move cursor to end of inserted checkbox
  local new_col = col + #checkbox_text
  vim.api.nvim_win_set_cursor(win, { row + 1, new_col })

  if M.config.auto_insert_mode then
    vim.cmd("startinsert")
  end
end

---Insert markdown checkbox on line below current line
function M.insert_markdown_checkbox_below()
  if M.config.check_filetype and not is_markdown_buffer() then
    vim.notify("Not in a markdown buffer", vim.log.levels.WARN)
    return
  end

  local bufnr, win, row = get_cursor_info()
  local current_line = get_line(bufnr, row)
  local indent = get_indent(current_line)

  local checkbox = indent .. M.config.checkbox_style .. " "
  vim.api.nvim_buf_set_lines(bufnr, row + 1, row + 1, false, { checkbox })
  vim.api.nvim_win_set_cursor(win, { row + 2, #checkbox })

  if M.config.auto_insert_mode then
    vim.cmd("startinsert")
  end
end

---Check if current line has a checkbox
---@return boolean
function M.has_checkbox()
  local bufnr, _, row = get_cursor_info()
  local line = get_line(bufnr, row)
  local has_checkbox = find_checkbox(line)
  return has_checkbox
end

---Get checkbox state on current line
---@return string|nil state "checked", "unchecked", "partial", or nil if no checkbox
function M.get_checkbox_state()
  local bufnr, _, row = get_cursor_info()
  local line = get_line(bufnr, row)
  local has_checkbox, checkbox = find_checkbox(line)

  if not has_checkbox then
    return nil
  end

  if checkbox == "[ ]" then
    return "unchecked"
  elseif checkbox == "[x]" or checkbox == "[X]" then
    return "checked"
  elseif checkbox == "[-]" then
    return "partial"
  end

  return nil
end

return M
