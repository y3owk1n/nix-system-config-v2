---@class Restart
local M = {}

-- ------------------------------------------------------------------
-- Private variables and functions
-- ------------------------------------------------------------------
local session_file = vim.fn.stdpath("data") .. "/restart-session.vim"

---Check if a file exists and is readable
---@param file string
---@return boolean
local function file_readable(file)
  return vim.fn.filereadable(file) == 1
end

---Safely delete a file with error handling
---@param file string
---@return boolean success
local function safe_delete(file)
  local success = pcall(vim.fn.delete, file)
  return success and vim.fn.filereadable(file) == 0
end

---Get list of modified buffers
---@return table
local function get_modified_buffers()
  local modified = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        table.insert(modified, name)
      else
        table.insert(modified, "[No Name]")
      end
    end
  end
  return modified
end

---Create session with error handling
---@param file string
---@return boolean success
local function create_session(file)
  ---@diagnostic disable-next-line: param-type-mismatch
  local success, err = pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(file))
  if not success then
    vim.notify("Failed to create session: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return file_readable(file)
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class Restart.Config
---@field session_file? string Custom session file path
---@field auto_save? boolean Automatically save all buffers before restart
---@field confirm_restart? boolean Ask for confirmation before restart
---@field exclude_patterns? table Patterns to exclude from session
---@field restore_cursor? boolean Restore cursor position after restart
---@field notify_level? number Notification level (vim.log.levels)

M.config = {}

---@type Restart.Config
M.defaults = {
  session_file = nil, -- Uses default if nil
  auto_save = true,
  confirm_restart = false,
  exclude_patterns = {}, -- e.g. { "NERD_tree", "tagbar", "qf", "help" }
  restore_cursor = true,
  notify_level = vim.log.levels.INFO,
}

---Setup the plugin
---@param user_config? Restart.Config
function M.setup(user_config)
  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  -- Use custom session file if provided
  if M.config.session_file then
    session_file = vim.fn.expand(M.config.session_file)
  end

  -- Create directory if it doesn't exist
  local session_dir = vim.fn.fnamemodify(session_file, ":h")
  if vim.fn.isdirectory(session_dir) == 0 then
    vim.fn.mkdir(session_dir, "p")
  end

  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    nested = true,
    callback = function()
      if file_readable(session_file) then
        vim.schedule(function()
          M._restore_session()
        end)
      end
    end,
  })

  -- Create user commands
  vim.api.nvim_create_user_command("RestartVim", function()
    M.save_restart()
  end, { desc = "Save session and restart Neovim" })

  vim.api.nvim_create_user_command("RestartVimForce", function()
    M.save_restart(true)
  end, { desc = "Force restart without confirmation" })
end

---Internal function to restore session
function M._restore_session()
  ---@diagnostic disable-next-line: param-type-mismatch
  local success, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(session_file))

  if success then
    if M.config.notify_level <= vim.log.levels.INFO then
      vim.notify("Session restored successfully", M.config.notify_level)
    end

    -- Clean up session file
    if not safe_delete(session_file) then
      vim.notify("Warning: Could not delete session file", vim.log.levels.WARN)
    end
  else
    vim.notify("Failed to restore session: " .. tostring(err), vim.log.levels.ERROR)
    safe_delete(session_file) -- Clean up corrupted session file
  end
end

---Check if restart is safe (no unsaved changes)
---@return boolean safe
---@return string[] modified_files
function M.check_restart_safety()
  local modified = get_modified_buffers()
  return #modified == 0, modified
end

---Save current state and restart Neovim
---@param force? boolean Skip confirmation dialog
function M.save_restart(force)
  -- Check for modified buffers if auto_save is disabled
  if not M.config.auto_save then
    local safe, modified = M.check_restart_safety()
    if not safe and not force then
      local choice = vim.fn.confirm(
        "You have unsaved changes in:\n" .. table.concat(modified, "\n") .. "\n\nContinue?",
        "&Yes\n&No",
        2
      )
      if choice ~= 1 then
        return
      end
    end
  end

  -- Ask for confirmation if enabled
  if M.config.confirm_restart and not force then
    local choice = vim.fn.confirm("Restart Neovim?", "&Yes\n&No", 2)
    if choice ~= 1 then
      return
    end
  end

  -- Save all buffers if auto_save is enabled
  if M.config.auto_save then
    ---@diagnostic disable-next-line: param-type-mismatch
    local save_success, save_err = pcall(vim.cmd, "silent! wall")
    if not save_success then
      vim.notify("Warning: Could not save all files: " .. tostring(save_err), vim.log.levels.WARN)
    end
  end

  -- Set session options
  local old_sessionoptions = vim.o.sessionoptions
  if M.config.exclude_patterns and #M.config.exclude_patterns > 0 then
    -- This is a simplified approach - you might want to implement more sophisticated filtering
    vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,terminal"
  end

  -- Create session
  if not create_session(session_file) then
    vim.o.sessionoptions = old_sessionoptions
    vim.notify("Failed to create session file. Restart cancelled.", vim.log.levels.ERROR)
    return
  end

  -- Restore session options
  vim.o.sessionoptions = old_sessionoptions

  if M.config.notify_level <= vim.log.levels.INFO then
    vim.notify("Session saved. Restarting Neovim...", M.config.notify_level)
  end

  -- Schedule restart to avoid issues
  vim.schedule(function()
    vim.cmd("restart")
  end)
end

---Get plugin status information
---@return table
function M.status()
  return {
    session_file = session_file,
    session_exists = file_readable(session_file),
    config = M.config,
    modified_buffers = get_modified_buffers(),
  }
end

---Clean up any existing session files
function M.cleanup()
  if file_readable(session_file) then
    safe_delete(session_file)
    vim.notify("Session file cleaned up", vim.log.levels.INFO)
  end
end

return M
