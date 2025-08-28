---@type PluginModule
local M = {}

M.name = "mini.pairs"

M.lazy = {
  event = "InsertEnter",
}

M.registry = {
  { src = "https://github.com/nvim-mini/mini.pairs", name = "mini.pairs" },
}

function M.setup()
  vim.pack.add({ "https://github.com/nvim-mini/mini.pairs" })

  local plugin_ok, plugin = pcall(require, "mini.pairs")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
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
  }

  plugin.setup(plugin_opts)
end

return M
