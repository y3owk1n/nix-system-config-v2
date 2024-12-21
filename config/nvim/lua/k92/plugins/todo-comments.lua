return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = { signs = false },
}
