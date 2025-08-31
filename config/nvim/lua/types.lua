---@class PluginModule
---@field name? string
---@field enabled? boolean
---@field requires? string[]
---@field setup? fun()
---@field priority? integer
---@field lazy? string | PluginModule.Lazy
---@field registry? vim.pack.Spec[]
---@field async? boolean -- whether to run setup asynchronously, true by default
---@field post_pack_changed? fun() -- for "install" and "update"

---@class PluginModule.Config
---@field mod_root? string
---@field local_dev_config? PluginModule.Config.LocalDevConfig

---@class PluginModule.Config.LocalDevConfig
---@field base_dir? string
---@field use_symlinks? boolean

---@class PluginModule.Resolved
---@field name? string
---@field path? string
---@field setup? fun()
---@field priority? integer
---@field requires? string[]
---@field lazy? string | PluginModule.Lazy | false
---@field loaded? boolean
---@field registry? vim.pack.Spec[]
---@field async? boolean -- whether to run setup asynchronously, true by default
---@field post_pack_changed? fun() -- for "install" and "update"

---@class PluginModule.ResolutionEntry
---@field name string
---@field ms number
---@field parent? PluginModule.Resolved
---@field async boolean

---@alias PluginModule.Lazy.Event "VeryLazy"|vim.api.keyset.events

---@class PluginModule.Lazy
---@field event? PluginModule.Lazy.Event|PluginModule.Lazy.Event[]
---@field ft? string|string[]
---@field keys? string|string[]
---@field cmd? string|string[]
---@field on_lsp_attach? string|string[]

---@class LspModule
---@field enabled? boolean
---@field setup? fun()
---@field async? boolean -- whether to run setup asynchronously, true by default

---@class LspModule.Resolved
---@field name? string
---@field path? string
---@field enabled? boolean
---@field setup? fun()
---@field loaded? boolean
---@field async? boolean -- whether to run setup asynchronously, true by default
