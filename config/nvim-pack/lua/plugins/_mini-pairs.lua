---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.pairs")

  if not plugin_ok then
    return
  end

  plugin.setup({
    modes = { insert = true, command = true, terminal = false },
    -- skip autopair when next character is one of these
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    -- skip autopair when the cursor is inside these treesitter nodes
    skip_ts = { "string" },
    -- skip autopair when next character is closing pair
    -- and there are more closing pairs than opening pairs
    skip_unbalanced = true,
    -- better deal with markdown code blocks
    markdown = true,
  })
end

return M
