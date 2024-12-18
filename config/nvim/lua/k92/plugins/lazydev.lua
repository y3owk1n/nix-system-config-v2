return {
	'folke/lazydev.nvim',
	lazy = true,
	ft = 'lua',
	cmd = 'LazyDev',
	opts = {
		library = {
			{ path = '${3rd}/luv/library', words = { 'vim%.uv' } },
			{ path = 'snacks.nvim', words = { 'Snacks' } },
			{ path = 'lazy.nvim', words = { 'Lazy' } },
		},
	},
	specs = {
		{ 'Bilal2453/luvit-meta', lazy = true },
	},
}
