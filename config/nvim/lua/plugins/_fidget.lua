---@type PluginModule
local M = {}

M.enabled = false

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

    --- render to a split buffer
    local lines = {}
    for _, entry in ipairs(history) do
      local msg = entry.message
      if entry.key then
        msg = string.format("%s:%s", msg, entry.key)
      end
      table.insert(lines, msg)
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
    end)
  end, { desc = "Notification History" })
  vim.keymap.set("n", "<leader>un", function()
    plugin.notification.clear()
  end, { desc = "Dismiss All Notifications" })
end

return M
