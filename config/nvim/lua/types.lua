---@class PluginModule
---@field name? string
---@field enabled? boolean
---@field requires? string[]
---@field setup? function
---@field priority? integer
---@field lazy? string | PluginModule.Lazy
---@field registry? (string|vim.pack.Spec)[]
---@field build? string|function

---@class PluginModule.Resolved
---@field name? string
---@field path? string
---@field setup? function
---@field priority? integer
---@field requires? string[]
---@field lazy? string | PluginModule.Lazy | false
---@field loaded? boolean
---@field registry? (string|vim.pack.Spec)[]
---@field build? string|function

---@class PluginModule.ResolutionEntry
---@field name string
---@field ms number
---@field parent? PluginModule.Resolved

---@class PluginModule.Lazy
---@field event? vim.api.keyset.events|vim.api.keyset.events[]
---@field ft? string|string[]
---@field keys? string|string[]
---@field cmd? string|string[]
---@field on_lsp_attach? string|string[]

---@class LspModule
---@field enabled? boolean
---@field setup? function

---@class LspModule.Resolved
---@field name? string
---@field path? string
---@field enabled? boolean
---@field setup? function
---@field loaded? boolean
