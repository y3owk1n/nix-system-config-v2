---@type PluginModule
local M = {}

M.name = "mini.icons"

M.lazy = {
  event = { "VeryLazy" },
}

M.registry = {
  { src = "https://github.com/echasnovski/mini.icons", name = "mini.icons" },
}

function M.setup()
  local plugin_ok, plugin = pcall(require, "mini.icons")

  if not plugin_ok then
    return
  end

  local plugin_opts = {
    file = {
      [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
      ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
      [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
      [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
      [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
      ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
      ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
      ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
      ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
    },
    filetype = {
      dotenv = { glyph = "", hl = "MiniIconsYellow" },
      gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
    },
  }

  plugin.setup(plugin_opts)

  plugin.mock_nvim_web_devicons()
end

return M
