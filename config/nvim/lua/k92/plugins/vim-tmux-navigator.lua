---@type LazySpec
return {
	"alexghergh/nvim-tmux-navigation",
	enabled = not vim.g.enable_minimal_config,
	event = "VeryLazy",
	cmd = {
		"NvimTmuxNavigateLeft",
		"NvimTmuxNavigateDown",
		"NvimTmuxNavigateUp",
		"NvimTmuxNavigateRight",
		"NvimTmuxNavigatePrevious",
	},
	opts = {},
	keys = {
		{ "<c-h>", "<cmd>NvimTmuxNavigateLeft<cr>" },
		{ "<c-j>", "<cmd>NvimTmuxNavigateDown<cr>" },
		{ "<c-k>", "<cmd>NvimTmuxNavigateUp<cr>" },
		{ "<c-l>", "<cmd>NvimTmuxNavigateRight<cr>" },
	},
}
