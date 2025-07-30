---@class PluginModule
---@field enabled? boolean
---@field requires? string[]
---@field setup? fun()
---@field priority? integer
---@field lazy? string | PluginModule.Lazy

---@class PluginModule.Resolved
---@field name? string
---@field setup? fun()
---@field priority? integer
---@field requires? string[]
---@field lazy? string | PluginModule.Lazy | false
---@field loaded? boolean

---@class PluginModule.Lazy
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field keys? PluginModule.Lazy.Keys[]
---@field on_lsp_attach? string|string[]

---@class PluginModule.Lazy.Keys
---@field mode? string|string[]
---@field lhs? string
---@field rhs? string|function
---@field opts? vim.keymap.set.Opts
