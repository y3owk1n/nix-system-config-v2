return {
	"ibhagwan/fzf-lua",
	---@module 'fzf-lua'
	---@type function|FzfLuaOpts
	opts = function(_, opts)
		local config = require("fzf-lua.config")
		-- local actions = require("fzf-lua.actions")

		config.defaults.keymap.fzf["ctrl-d"] = "preview-page-down"
		config.defaults.keymap.fzf["ctrl-u"] = "preview-page-up"
		config.defaults.keymap.builtin["<c-d>"] = "preview-page-down"
		config.defaults.keymap.builtin["<c-u>"] = "preview-page-up"

		-- remove unwanted keybindings
		opts.files.actions = {}
		opts.grep.actions = {}

		opts.defaults = {
			formatter = "path.filename_first",
		}
	end,
}
