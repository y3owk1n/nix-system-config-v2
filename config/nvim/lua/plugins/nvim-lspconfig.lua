return {
	"neovim/nvim-lspconfig",
	-- other settings removed for brevity
	---@class PluginLspOpts
	opts = {
		servers = {
			biome = {},
			tsserver = {
				enabled = false,
			},
			ts_ls = {
				enabled = false,
			},
			vtsls = {
				enabled = false,
			},
		},
	},
}
