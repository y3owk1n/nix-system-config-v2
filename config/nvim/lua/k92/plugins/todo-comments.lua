return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = { signs = false },
}

-- vim: ts=2 sts=2 sw=2 et
