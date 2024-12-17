return {
	'folke/todo-comments.nvim',
	lazy = true,
	event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
	dependencies = { 'nvim-lua/plenary.nvim' },
	opts = { signs = false },
}
