---@class LspRename
local M = {}

---@type boolean
local did_setup = false

-- ------------------------------------------------------------------
-- Private variables and functions
-- ------------------------------------------------------------------

-- Utility function for notifications (fallback if no notification plugin)
local function notify(msg, level)
  level = level or vim.log.levels.INFO
  if vim.notify then
    vim.notify(msg, level, { title = "LSP Rename" })
  else
    print(msg)
  end
end

-- Utility function for error notifications
local function notify_error(msg)
  notify(msg, vim.log.levels.ERROR)
end

-- Utility function for info notifications
local function notify_info(msg)
  if M.config.show_progress then
    notify(msg, vim.log.levels.INFO)
  end
end

-- Normalize path function (replacement for the missing svim.fs.normalize)
local function normalize_path(path)
  -- Expand ~ and environment variables
  path = vim.fn.expand(path)
  -- Convert to absolute path
  if not vim.fn.fnamemodify(path, ":p"):match("^/") and not path:match("^%a:") then
    path = vim.fn.fnamemodify(path, ":p")
  end
  -- Normalize path separators and resolve . and ..
  return vim.fn.resolve(vim.fn.fnamemodify(path, ":p"))
end

-- Validate file paths
local function validate_paths(from, to)
  if not from or from == "" then
    notify_error("Source file path is empty")
    return false
  end

  if not to or to == "" then
    notify_error("Destination file path is empty")
    return false
  end

  if not vim.fn.filereadable(from) then
    notify_error("Source file does not exist or is not readable: " .. from)
    return false
  end

  if from == to then
    notify_error("Source and destination paths are the same")
    return false
  end

  return true
end

-- Create directory if it doesn't exist
local function ensure_dir(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    local ok = vim.fn.mkdir(dir, "p")
    if ok == 0 then
      notify_error("Failed to create directory: " .. dir)
      return false
    end
  end
  return true
end

-- Auto-save all modified buffers
local function auto_save_buffers()
  if not M.config.auto_save then
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      vim.api.nvim_buf_call(buf, function()
        if vim.bo.buftype == "" and vim.fn.bufname() ~= "" then
          vim.cmd("silent! write")
        end
      end)
    end
  end
end

-- Rename a file and update buffers
---@param from string
---@param to string
---@return boolean success
function M._rename(from, to)
  from = normalize_path(from)
  to = normalize_path(to)

  if not validate_paths(from, to) then
    return false
  end

  -- Ensure destination directory exists
  if not ensure_dir(to) then
    return false
  end

  -- Check if destination exists
  if vim.fn.filereadable(to) == 1 then
    local choice = vim.fn.confirm("File already exists: " .. to .. "\nOverwrite?", "&Yes\n&No", 2)
    if choice ~= 1 then
      return false
    end
  end

  -- Auto-save buffers before renaming
  auto_save_buffers()

  -- Rename the file
  local ret = vim.fn.rename(from, to)
  if ret ~= 0 then
    notify_error("Failed to rename file: " .. vim.fn.fnamemodify(from, ":t"))
    return false
  end

  notify_info("File renamed successfully")

  -- Update buffer references
  local from_buf = vim.fn.bufnr(from)
  if from_buf >= 0 then
    local to_buf = vim.fn.bufadd(to)
    vim.bo[to_buf].buflisted = true

    -- Update all windows showing the old buffer
    for _, win in ipairs(vim.fn.win_findbuf(from_buf)) do
      vim.api.nvim_win_call(win, function()
        vim.cmd("buffer " .. to_buf)
      end)
    end

    -- Delete the old buffer
    vim.api.nvim_buf_delete(from_buf, { force = true })
  end

  return true
end

-- Let LSP clients know that a file has been renamed
---@param from string
---@param to string
---@param rename? function
function M.on_rename_file(from, to, rename)
  local changes = {
    files = {
      {
        oldUri = vim.uri_from_fname(from),
        newUri = vim.uri_from_fname(to),
      },
    },
  }

  -- Get active LSP clients (compatible with both old and new API)
  local get_clients = vim.lsp.get_clients
  local clients = get_clients()

  -- Send willRenameFiles requests
  local will_rename_responses = {}
  for _, client in ipairs(clients) do
    if client:supports_method("workspace/willRenameFiles") then
      notify_info("Requesting rename permission from " .. client.name)
      local success, resp = pcall(function()
        return client:request_sync("workspace/willRenameFiles", changes, M.config.lsp_timeout, 0)
      end)

      if success and resp and resp.result then
        will_rename_responses[client.name] = resp.result
      elseif not success then
        notify_error("LSP willRenameFiles request failed for " .. client.name .. ": " .. tostring(resp))
      end
    end
  end

  -- Apply workspace edits from willRenameFiles responses
  for client_name, result in pairs(will_rename_responses) do
    local client = nil
    for _, c in ipairs(clients) do
      if c.name == client_name then
        client = c
        break
      end
    end

    if client then
      local success, err = pcall(vim.lsp.util.apply_workspace_edit, result, client.offset_encoding)
      if not success then
        notify_error("Failed to apply workspace edit from " .. client_name .. ": " .. tostring(err))
      end
    end
  end

  -- Perform the actual rename
  if rename then
    rename()
  end

  -- Send didRenameFiles notifications
  for _, client in ipairs(clients) do
    if client:supports_method("workspace/didRenameFiles") then
      local success, err = pcall(function()
        client:notify("workspace/didRenameFiles", changes)
      end)

      if not success then
        notify_error("LSP didRenameFiles notification failed for " .. client.name .. ": " .. tostring(err))
      end
    end
  end
end

-- Main rename function
-- Renames the provided file, or the current buffer's file.
-- Prompts for the new filename if `to` is not provided.
---@param opts? {from?: string, to?: string, on_rename?: fun(to: string, from: string, ok: boolean)}
function M.rename_file(opts)
  opts = opts or {}

  -- Determine source file
  local from = opts.from or vim.api.nvim_buf_get_name(0)
  if from == "" then
    notify_error("No file to rename (current buffer has no associated file)")
    return
  end

  from = normalize_path(from)
  local to = opts.to and normalize_path(opts.to) or nil

  -- Function to perform the rename
  local function perform_rename()
    if not to then
      notify_error("Destination path is required")
      return
    end

    -- Optional confirmation
    if M.config.confirm and not opts.to then
      local from_display = vim.fn.fnamemodify(from, ":~")
      local to_display = vim.fn.fnamemodify(to, ":~")
      local choice =
        vim.fn.confirm(string.format("Rename file?\nFrom: %s\nTo: %s", from_display, to_display), "&Yes\n&No", 1)
      if choice ~= 1 then
        return
      end
    end

    M.on_rename_file(from, to, function()
      local ok = M._rename(from, to)
      if opts.on_rename then
        opts.on_rename(to, from, ok)
      end
    end)
  end

  -- If destination is provided, rename immediately
  if to then
    return perform_rename()
  end

  -- Determine appropriate root directory for input completion
  local root = vim.fn.getcwd()
  if not from:find(vim.pesc(root), 1) then
    root = vim.fn.fnamemodify(from, ":h")
  end

  -- Calculate relative path for default input
  local from_relative = vim.fn.fnamemodify(from, ":.")
  if from:find(vim.pesc(root), 1) then
    from_relative = from:sub(#root + 2)
  end

  -- Prompt for new filename
  vim.ui.input({
    prompt = "New file name: ",
    default = from_relative,
    completion = "file",
  }, function(input)
    if not input or input == "" or input == from_relative then
      return
    end

    -- Handle relative vs absolute paths
    if vim.fn.fnamemodify(input, ":p") == input then
      -- Absolute path provided
      to = normalize_path(input)
    else
      -- Relative path provided
      to = normalize_path(root .. "/" .. input)
    end

    perform_rename()
  end)
end

-- ------------------------------------------------------------------
-- User commands
-- ------------------------------------------------------------------

-- Command setup
local function create_commands()
  vim.api.nvim_create_user_command("LspRename", function(opts)
    if opts.args and opts.args ~= "" then
      M.rename_file({ to = opts.args })
    else
      M.rename_file()
    end
  end, {
    nargs = "?",
    complete = "file",
    desc = "Rename current file with LSP integration",
  })

  vim.api.nvim_create_user_command("LspRenameFile", function(opts)
    local args = vim.split(opts.args, "%s+")
    if #args >= 2 then
      M.rename_file({ from = args[1], to = args[2] })
    elseif #args == 1 then
      M.rename_file({ from = args[1] })
    else
      M.rename_file()
    end
  end, {
    nargs = "*",
    complete = "file",
    desc = "Rename specified file with LSP integration",
  })
end

-- ------------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------------

---@class LspRename.Config
---@field confirm? boolean Show confirmation dialog before renaming
---@field auto_save? boolean Auto-save all buffers before renaming
---@field lsp_timeout? number Timeout for LSP requests (ms)
---@field show_progress? boolean Show progress notifications

---@type LspRename.Config
M.config = {}

---@type LspRename.Config
M.defaults = {
  -- Show confirmation dialog before renaming
  confirm = true,
  -- Auto-save all buffers before renaming
  auto_save = true,
  -- Timeout for LSP requests (ms)
  lsp_timeout = 3000,
  -- Show progress notifications
  show_progress = true,
}

-- Setup function for configuration
---@param user_config? LspRename.Config
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", M.defaults, user_config or {})

  create_commands()

  did_setup = true
end

-- Convenience function for current buffer
function M.rename_current_file()
  M.rename_file()
end

return M
