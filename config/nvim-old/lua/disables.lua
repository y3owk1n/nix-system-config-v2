local M = {}

---@type boolean
local did_setup = false

local function disable_builtin_plugins()
  local plugins = {
    "2html_plugin",
    "tohtml",
    "man",
    "getscript",
    "getscriptPlugin",
    "logipat",
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "rrhelper",
    "spellfile_plugin",
    "vimball",
    "vimballPlugin",
    "tutor",
    "synmenu",
    "optwin",
    "bugreport",
    -- reconsider when needed
    "compiler", -- remove this if want to use `makeprg`
    "gzip",
    "zip",
    "zipPlugin",
    "tar",
    "tarPlugin",
  }
  for _, name in ipairs(plugins) do
    vim.g["loaded_" .. name] = 1
  end
end

local function disable_builtin_providers()
  local providers = {
    "node",
    "perl",
    "ruby",
    "python3",
  }
  for _, name in ipairs(providers) do
    vim.g["loaded_" .. name .. "_provider"] = 0
  end
end

function M.setup()
  if did_setup then
    return
  end

  disable_builtin_plugins()
  disable_builtin_providers()

  did_setup = true
end

return M
