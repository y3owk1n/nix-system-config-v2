---@type LazySpec
return {
	{
		"y3owk1n/tool-resolver.nvim",
		-- dir = "~/Dev/tool-resolver.nvim", -- Your path
		cmd = {
			"ToolResolverGet",
			"ToolResolverClearCache",
			"ToolResolverGetCache",
		},
		---@type ToolResolver.Config
		opts = {
			fallbacks = {
				biome = "biome",
				prettier = "prettierd",
			},
		},
	},
}
