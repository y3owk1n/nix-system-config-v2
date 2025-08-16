local M = {}

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

function M.setup()
  require("k92.lsp.bash")
  require("k92.lsp.biome")
  require("k92.lsp.docker")
  require("k92.lsp.eslint")
  require("k92.lsp.gh-actions")
  require("k92.lsp.go")
  require("k92.lsp.json")
  require("k92.lsp.just")
  require("k92.lsp.lua")
  require("k92.lsp.marksman")
  require("k92.lsp.nil")
  require("k92.lsp.prisma")
  require("k92.lsp.tailwindcss")
  require("k92.lsp.vtsls")
  require("k92.lsp.yaml")

  vim.schedule(setup_progress_spinner)
end

return M
