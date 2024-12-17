return {
	'iamcco/markdown-preview.nvim',
	lazy = true,
	cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
	build = function()
		require('lazy').load { plugins = { 'markdown-preview.nvim' } }
		vim.fn['mkdp#util#install']()
	end,
	init = function()
		vim.g.mkdp_filetypes = { 'markdown' }
	end,
	ft = { 'markdown' },
	keys = {
		{
			'<leader>cp',
			ft = 'markdown',
			'<cmd>MarkdownPreviewToggle<cr>',
			desc = 'Markdown Preview',
		},
	},
}
