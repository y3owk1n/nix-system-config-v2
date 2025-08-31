local M = {}

-----------------------------------------------------------------------------//
-- Configuration
-----------------------------------------------------------------------------//

---@type string
local mad_base_path

---@type boolean
local did_setup = false

-----------------------------------------------------------------------------//
-- State & caches
-----------------------------------------------------------------------------//

---Cache discovered modules
---@type LspModule.Resolved[]
local _discovered_modules = nil

local ASYNC_SLICE_MS = 16

-----------------------------------------------------------------------------//
-- Utilities
-----------------------------------------------------------------------------//

local log = {
  warn = function(msg)
    vim.notify(msg, vim.log.levels.WARN)
  end,
  error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR)
  end,
}

-----------------------------------------------------------------------------//
-- Discovery
-----------------------------------------------------------------------------//

---Discover plugin modules from filesystem
---@return LspModule.Resolved[]
local function discover()
  if _discovered_modules then
    return _discovered_modules
  end

  ---@type LspModule.Resolved[]
  local modules = {}

  local files = vim.fs.find(function(name)
    return name:sub(-4) == ".lua"
  end, { type = "file", limit = math.huge, path = mad_base_path })

  for _, file in ipairs(files) do
    local rel = file:sub(#mad_base_path + 2, -5):gsub("/", ".")
    if rel ~= "init" then
      local path = M.config.mod_root .. "." .. rel
      local ok, chunk = pcall(loadfile, file)

      if not ok or type(chunk) ~= "function" then
        log.error(("Bad file %s: %s"):format(file, chunk))
        goto continue
      end

      local env = setmetatable({ vim = vim }, { __index = _G })
      setfenv(chunk, env)
      local success, mod = pcall(chunk)
      if not success or type(mod) ~= "table" or type(mod.setup) ~= "function" then
        log.warn(("Plugin %s does not export valid setup"):format(path))
        goto continue
      end

      if mod.enabled == false then
        -- log.warn(("Plugin %s is disabled"):format(path))
        goto continue
      end

      local name = mod.name or path

      ---@param x boolean|nil
      ---@param default boolean
      local function parse_boolean(x, default)
        if x == nil then
          return default
        end

        if type(x) == "boolean" then
          return x
        end

        return default
      end

      ---@type LspModule.Resolved
      local entry = {
        name = name,
        path = path,
        setup = mod.setup,
        loaded = false,
        async = parse_boolean(mod.async, true),
        failed = false,
        retry_count = 0,
      }

      table.insert(modules, entry)
      ::continue::
    end
  end

  _discovered_modules = modules
  return modules
end

-----------------------------------------------------------------------------//
-- Safe setup
-----------------------------------------------------------------------------//

---Safely setup a plugin module.
---@param mod LspModule.Resolved
---@return boolean success, string? error_message
local function setup_one(mod)
  if mod.loaded then
    return true
  end

  if mod.failed then
    return false, "Lsp Module previously failed"
  end

  local t0 = vim.uv.hrtime()

  local ok, data = pcall(require, mod.path)
  if not ok then
    local error_msg = string.format("Failed to require: %s", data)
    log.error(string.format("Lsp Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg
    return false, error_msg
  end

  -- Validate that the module has a setup function
  if type(data.setup) ~= "function" then
    local error_msg = "Lsp Module does not export a setup function"
    log.error(string.format("Lsp Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg
    return false, error_msg
  end

  -- run setup with timeout protection
  local setup_ok, setup_err
  if M.config.setup_timeout and M.config.setup_timeout > 0 then
    -- Add timeout protection if configured
    local timeout_ms = M.config.setup_timeout
    local timed_out = false

    local timer = vim.uv.new_timer()
    if timer and timeout_ms then
      timer:start(timeout_ms, 0, function()
        timed_out = true
        timer:stop()
        timer:close()
      end)
    end

    setup_ok, setup_err = pcall(data.setup)

    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end

    if timed_out then
      setup_ok = false
      setup_err = string.format("Setup timed out after %dms", timeout_ms)
    end
  else
    setup_ok, setup_err = pcall(data.setup)
  end

  if not setup_ok then
    local error_msg = string.format("Setup failed: %s", setup_err)
    log.error(string.format("Module %s: %s", mod.name, error_msg))
    mod.failed = true
    mod.failure_reason = error_msg

    return false, error_msg
  end

  local ms = (vim.uv.hrtime() - t0) / 1e6

  mod.loaded = true
  mod.load_time_ms = ms

  return true
end

---Safely setup a module asynchronously.
---@param mod LspModule.Resolved
---@param on_done? fun(success: boolean, error?: string)
local function async_setup_one(mod, on_done)
  if mod.loaded then
    if on_done then
      on_done(true)
    end
    return true
  end

  if mod.failed then
    if on_done then
      on_done(false, mod.failure_reason)
    end
    return false
  end

  local co = coroutine.create(function()
    local ok, data = pcall(require, mod.path)
    if not ok then
      local error_msg = string.format("Failed to require: %s", data)
      mod.failed = true
      mod.failure_reason = error_msg
      log.error(string.format("Async module %s: %s", mod.name, error_msg))
      return false, error_msg
    end

    -- start measuring
    local t0 = vim.uv.hrtime()

    -- Validate setup function
    if type(data.setup) ~= "function" then
      local error_msg = "Module does not export a setup function"
      mod.failed = true
      mod.failure_reason = error_msg
      log.error(string.format("Async module %s: %s", mod.name, error_msg))
      return false, error_msg
    end

    -- Run setup with slice yielding
    local setup_start = vim.uv.hrtime()
    local setup_ok, setup_err = pcall(data.setup)

    if not setup_ok then
      local error_msg = string.format("Async setup failed: %s", setup_err)
      mod.failed = true
      mod.failure_reason = error_msg
      log.error(string.format("Async module %s: %s", mod.name, error_msg))

      return false, error_msg
    end

    -- Check if we should yield after setup (if it took too long)
    local setup_duration = (vim.uv.hrtime() - setup_start) / 1e6
    if setup_duration > ASYNC_SLICE_MS then
      coroutine.yield() -- yield to UI
    end

    local ms = (vim.uv.hrtime() - t0) / 1e6

    mod.loaded = true
    mod.load_time_ms = ms

    return true
  end)

  local function tick()
    local co_ok, success_or_err, error_msg = coroutine.resume(co)

    if not co_ok then
      -- Coroutine itself failed (programming error)
      local full_error = string.format("Coroutine error in %s: %s", mod.name, debug.traceback(co, success_or_err))
      log.error(full_error)
      mod.failed = true
      mod.failure_reason = success_or_err
      if on_done then
        on_done(false, success_or_err)
      end
      return
    end

    if coroutine.status(co) == "dead" then
      -- Coroutine completed
      local success = success_or_err
      if success then
        if on_done then
          on_done(true)
        end
      else
        if on_done then
          on_done(false, error_msg)
        end
      end
    else
      -- Coroutine yielded, schedule next tick
      vim.defer_fn(tick, 0)
    end
  end
  tick()
end

-----------------------------------------------------------------------------//
-- Setup
-----------------------------------------------------------------------------//

---Setup all discovered modules.
---@return nil
local function setup_modules()
  for _, mod in ipairs(_discovered_modules) do
    if mod.async then
      async_setup_one(mod)
    else
      setup_one(mod)
    end
  end
end

-----------------------------------------------------------------------------//
-- Progress spinner
-----------------------------------------------------------------------------//

---Setup a progress spinner for LSP.
---@return nil
local function setup_progress_spinner()
  local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local last_spinner = 0
  local spinner_idx = 1

  ---@type table<string, uv.uv_timer_t|nil>
  local active_timers = {}

  vim.lsp.handlers["$/progress"] = function(_, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if not client or type(result.value) ~= "table" then
      return
    end

    local value = result.value
    local token = result.token
    local is_complete = value.kind == "end"
    local has_percentage = value.percentage ~= nil

    local function render()
      local progress_data = {
        percentage = value.percentage or nil,
        description = value.title or "Loading workspace",
        file_progress = value.message or nil,
      }

      if is_complete then
        progress_data.description = "Done"
        progress_data.file_progress = nil
      end

      local icon
      if is_complete then
        icon = " "
      else
        local now = vim.uv.hrtime()
        if now - last_spinner > 80e6 then
          spinner_idx = (spinner_idx % #spinner_chars) + 1
          last_spinner = now
        end
        icon = spinner_chars[spinner_idx]
      end

      vim.notify("", vim.log.levels.INFO, {
        id = string.format("lsp_progress_%s_%s", client.name, token),
        title = client.name,
        _notif_formatter = function(opts)
          local notif = opts.notif
          local _notif_formatter_data = notif._notif_formatter_data

          if not _notif_formatter_data then
            return {}
          end

          local separator = { display_text = " " }

          local icon_hl = notif.hl_group or opts.log_level_map[notif.level].hl_group

          local percent_text = _notif_formatter_data.percentage
              and string.format("%3d%%", _notif_formatter_data.percentage)
            or nil

          local description_text = _notif_formatter_data.description

          local file_progress_text = _notif_formatter_data.file_progress or nil

          local client_name = client.name

          ---@type Notifier.FormattedNotifOpts[]
          local entries = {}

          if icon then
            table.insert(entries, { display_text = icon, hl_group = icon_hl })
            table.insert(entries, separator)
          end

          if percent_text then
            table.insert(entries, { display_text = percent_text, hl_group = "Normal" })
            table.insert(entries, separator)
          end

          table.insert(entries, { display_text = description_text, hl_group = "Comment" })

          if file_progress_text then
            table.insert(entries, separator)
            table.insert(entries, { display_text = file_progress_text, hl_group = "Removed" })
          end

          if client_name then
            table.insert(entries, separator)
            table.insert(entries, { display_text = client_name, hl_group = "ErrorMsg" })
          end

          return entries
        end,
        _notif_formatter_data = progress_data,
      })
    end

    render()

    if not has_percentage then
      if not is_complete then
        local timer = active_timers[token]
        if not timer or timer:is_closing() then
          timer = vim.uv.new_timer()
          active_timers[token] = timer
        end

        if timer then
          timer:start(0, 150, function()
            vim.schedule(render)
          end)
        end
      else
        local timer = active_timers[token]
        if timer and not timer:is_closing() then
          timer:stop()
          timer:close()
          active_timers[token] = nil
        end
        vim.schedule(render)
      end
    end
  end
end

-- local function setup_completion()
--   vim.api.nvim_create_autocmd("LspAttach", {
--     callback = function(ev)
--       local client = vim.lsp.get_client_by_id(ev.data.client_id)
--       if not client then
--         return
--       end
--
--       if client:supports_method("textDocument/completion") then
--         vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy", "popup" }
--         vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
--
--         vim.keymap.set("i", "<CR>", function()
--           if vim.fn.pumvisible() == 1 then
--             return "<C-y>"
--           else
--             return "<CR>"
--           end
--         end, { expr = true, noremap = true })
--       end
--     end,
--   })
-- end
--
-----------------------------------------------------------------------------//
-- Public API
-----------------------------------------------------------------------------//

---@type LspModule.Config
local default_config = {
  mod_root = "lsp",
  path_to_mod_root = "/lua/",
  setup_timeout = nil, -- No timeout by default, set to number of ms to enable
  max_retries = 1, -- Number of retry attempts for failed modules
}

---@type LspModule.Config
M.config = {}

---Initialize the plugin manager.
---@param user_config? LspModule.Config
---@return nil
function M.setup(user_config)
  if did_setup then
    return
  end

  M.config = vim.tbl_deep_extend("force", default_config, user_config or {})
  mad_base_path = vim.fn.stdpath("config") .. M.config.path_to_mod_root .. M.config.mod_root

  discover()
  setup_modules()
  setup_progress_spinner()
  -- setup_completion()

  did_setup = true
end

return M
