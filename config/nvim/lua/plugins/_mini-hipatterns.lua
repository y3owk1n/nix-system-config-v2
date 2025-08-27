---@type PluginModule
local M = {}

M.name = "mini.hipatterns"

M.lazy = {
  event = { "BufReadPre", "BufNewFile" },
}

M.registry = {
  { src = "https://github.com/echasnovski/mini.hipatterns", name = "mini.hipatterns" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.hipatterns")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    highlighters = {
      fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
      hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
      todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
      note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
    },
  }

  plugin.setup(plugin_opts)
end

return M
