return {
	'MeanderingProgrammer/render-markdown.nvim',
	lazy = true,
	event = { 'BufReadPre' },
	opts = {
		code = {
			sign = false,
			width = 'block',
			right_pad = 1,
		},
		heading = {
			sign = false,
			icons = {},
		},
	},
	ft = { 'markdown', 'norg', 'rmd', 'org' },
	config = function(_, opts)
		require('render-markdown').setup(opts)
		Snacks.toggle({
			name = 'Render Markdown',
			get = function()
				return require('render-markdown.state').enabled
			end,
			set = function(enabled)
				local m = require 'render-markdown'
				if enabled then
					m.enable()
				else
					m.disable()
				end
			end,
		}):map '<leader>um'
	end,
}
