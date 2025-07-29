---@type PluginModule
local M = {}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.icons")

  if not plugin_ok then
    return
  end

  plugin.setup({
    file = {
      [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
      ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
    },
    filetype = {
      dotenv = { glyph = "", hl = "MiniIconsYellow" },
    },
  })

  package.preload["nvim-web-devicons"] = function()
    plugin.mock_nvim_web_devicons()
    return package.loaded["nvim-web-devicons"]
  end
end

return M
