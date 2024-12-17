return {
	"neovim/nvim-lspconfig",
	-- other settings removed for brevity
	---@class PluginLspOpts
	opts = {
		diagnostics = {
			float = {
				border = "rounded",
			},
		},
		servers = {
			biome = {},
		},
	},
}
