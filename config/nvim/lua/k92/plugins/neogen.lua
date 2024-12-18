return {
	'danymat/neogen',
	lazy = true,
	event = 'VeryLazy',
	cmd = 'Neogen',
	keys = {
		{
			'<leader>cn',
			function()
				require('neogen').generate()
			end,
			desc = 'Generate Annotations (Neogen)',
		},
	},
	opts = function(_, opts)
		if opts.snippet_engine ~= nil then
			return
		end

		if vim.snippet then
			opts.snippet_engine = 'nvim'
		end
	end,
}
