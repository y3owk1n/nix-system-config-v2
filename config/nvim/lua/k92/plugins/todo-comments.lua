---@type LazySpec
return {
	"folke/todo-comments.nvim",
	cmd = { "TodoTrouble", "TodoFzfLua" },
	event = { "VeryLazy" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = { signs = false },
	keys = {
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next Todo Comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous Todo Comment",
		},
		{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
		{
			"<leader>xT",
			"<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>",
			desc = "Todo/Fix/Fixme (Trouble)",
		},
		{ "<leader>st", "<cmd>TodoFzfLua<cr>", desc = "Todo" },
		{ "<leader>sT", "<cmd>TodoFzfLua keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
	},
}
