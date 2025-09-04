---@class PluginModule
---@field name? string
---@field enabled? boolean
---@field requires? string[]
---@field after? string[]
---@field setup? fun()
---@field priority? integer
---@field lazy? string | PluginModule.Lazy
---@field registry? vim.pack.Spec[]
---@field async? boolean -- whether to run setup asynchronously, true by default
---@field post_pack_changed? fun() -- for "install" and "update"

---@class PluginModule.Config
---@field mod_root? string
---@field path_to_mod_root? string -- "/lua/abc/def/", starts and end with "/", excludes `mod_root`
---@field local_dev_config? PluginModule.Config.LocalDevConfig
---@field setup_timeout number? -- timeout for setup functions in milliseconds
---@field max_retries number? -- maximum retry attempts for failed modules

---@class PluginModule.Config.LocalDevConfig
---@field base_dir? string
---@field use_symlinks? boolean

---@class PluginModule.Resolved
---@field name? string
---@field path? string
---@field setup? fun()
---@field priority? integer
---@field requires? string[]
---@field after? string[]
---@field lazy? string | PluginModule.Lazy | false
---@field loaded? boolean
---@field registry? vim.pack.Spec[]
---@field async? boolean -- whether to run setup asynchronously, true by default
---@field post_pack_changed? fun() -- for "install" and "update"
---@field failed boolean? -- indicates if module failed to load
---@field failure_reason string? -- reason for failure
---@field load_time_ms number? -- time taken to load
---@field retry_count number? -- number of retry attempts

---@class PluginModule.ResolutionEntry
---@field name string
---@field ms number
---@field parent? PluginModule.Resolved
---@field async boolean
---@field errors string[]? -- any non-fatal errors during loading
---@field after string[]? -- names of modules that were triggered after this one

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

---@class LspModule.Config
---@field mod_root? string
---@field path_to_mod_root? string -- "/lua/abc/def/", starts and end with "/", excludes `mod_root`
---@field setup_timeout number? -- timeout for setup functions in milliseconds
---@field max_retries number? -- maximum retry attempts for failed modules

---@class LspModule.Resolved
---@field name? string
---@field path? string
---@field enabled? boolean
---@field setup? fun()
---@field loaded? boolean
---@field async? boolean -- whether to run setup asynchronously, true by default
---@field failed boolean? -- indicates if module failed to load
---@field retry_count number? -- number of retry attempts
---@field failure_reason string? -- reason for failure
---@field load_time_ms number? -- time taken to load
