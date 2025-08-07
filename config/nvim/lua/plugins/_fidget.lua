---@type PluginModule
local M = {}

-- M.enabled = false

M.name = "fidget"

M.registry = {
  "https://github.com/j-hui/fidget.nvim",
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "fidget")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    notification = {
      override_vim_notify = true,
      window = {
        winblend = 0,
      },
    },
  }

  plugin.setup(plugin_opts)

  ---notifier keymaps
  vim.keymap.set("n", "<leader>N", function()
    local history = plugin.notification.get_history()

    if #history == 0 then
      vim.notify("No notifications to show", vim.log.levels.INFO)
      return
    end

    ---@type table<integer, { text: string|osdate, hl_group: string }>[]
    local segments = {}

    for i = #history, 1, -1 do
      local entry = history[i]

      local timetamp = entry.last_updated

      local pretty_time = os.date("%Y-%m-%d %H:%M:%S", timetamp)

      local separator = {
        text = " ",
      }

      ---@type table<string, string>
      local hl_groups = {
        INFO = "MoreMsg",
        WARN = "WarningMsg",
        ERROR = "ErrorMsg",
        DEBUG = "Debug",
        TRACE = "Comment",
      }

      segments[i] = {
        separator,
        {
          text = pretty_time,
          hl_group = "Comment",
        },
        separator,
        {
          text = entry.message,
          hl_group = hl_groups[entry.style],
        },
      }
    end

    --- render to a split buffer
    local lines = {}

    for i = 1, #segments do
      local flattened = {}
      local segment = segments[i]
      for j = 1, #segment do
        local item = segment[j]
        table.insert(flattened, item.text)
      end
      lines[i] = table.concat(flattened, "")
    end

    local title = "fidget://history"

    local old_buf = vim.fn.bufnr(title)
    if old_buf ~= -1 then
      vim.api.nvim_buf_delete(old_buf, { force = true })
    end

    vim.schedule(function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].filetype = "cmd"
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.bo[buf].modifiable = false
      vim.bo[buf].readonly = true
      vim.bo[buf].buflisted = false
      vim.api.nvim_buf_set_name(buf, title)
      vim.cmd("vsplit | buffer " .. buf)

      local ns = vim.api.nvim_create_namespace("fidget_history")
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

      for i = 1, #segments do
        local segment = segments[i]
        local col = 0
        for j = 1, #segment do
          local item = segment[j]
          if item.hl_group then
            vim.api.nvim_buf_set_extmark(buf, ns, i - 1, col, {
              end_col = col + #item.text,
              hl_group = item.hl_group,
            })
          end
          col = col + #item.text
        end
      end
    end)
  end, { desc = "Notification History" })
  vim.keymap.set("n", "<leader>un", function()
    plugin.notification.clear()
  end, { desc = "Dismiss All Notifications" })
end

return M
