---@type LazySpec
return {
	{
		"y3owk1n/dotmd.nvim",
		-- dir = "~/Dev/dotmd.nvim", -- Your path
		event = { "VeryLazy" },
		---@type DotMd.Config
		opts = {
			root_dir = "~/Library/Mobile Documents/com~apple~CloudDocs/Cloud Notes",
			-- root_dir = "~/dotmd",
			default_split = "vertical",
		},
		keys = {
			{
				"<leader>nc",
				function()
					require("dotmd").create_note()
				end,
				mode = "n",
				desc = "[DotMd] Create new note",
				noremap = true,
			},
			{
				"<leader>nt",
				function()
					require("dotmd").create_todo_today()
				end,
				mode = "n",
				desc = "[DotMd] Create todo for today",
				noremap = true,
			},
			{
				"<leader>ni",
				function()
					require("dotmd").inbox()
				end,
				mode = "n",
				desc = "[DotMd] Inbox",
				noremap = true,
			},
			{
				"<leader>nj",
				function()
					require("dotmd").create_journal()
				end,
				mode = "n",
				desc = "[DotMd] Create journal",
				noremap = true,
			},
			{
				"<leader>np",
				function()
					require("dotmd").navigate("previous")
				end,
				mode = "n",
				desc = "[DotMd] Navigate to previous todo",
				noremap = true,
			},
			{
				"<leader>nn",
				function()
					require("dotmd").navigate("next")
				end,
				mode = "n",
				desc = "[DotMd] Navigate to next todo",
				noremap = true,
			},
			{
				"<leader>snn",
				function()
					require("dotmd").pick({
						type = "notes",
					})
				end,
				mode = "n",
				desc = "[DotMd] Search notes",
				noremap = true,
			},
			{
				"<leader>snN",
				function()
					require("dotmd").pick({
						type = "notes",
						grep = true,
					})
				end,
				mode = "n",
				desc = "[DotMd] Search notes grep",
				noremap = true,
			},
			{
				"<leader>snt",
				function()
					require("dotmd").pick({
						type = "todos",
					})
				end,
				mode = "n",
				desc = "[DotMd] Search todos",
				noremap = true,
			},
			{
				"<leader>snT",
				function()
					require("dotmd").pick({
						type = "todos",
						grep = true,
					})
				end,
				mode = "n",
				desc = "[DotMd] Search todos grep",
				noremap = true,
			},
			{
				"<leader>snj",
				function()
					require("dotmd").pick({
						type = "journal",
					})
				end,
				mode = "n",
				desc = "[DotMd] Search journal",
				noremap = true,
			},
			{
				"<leader>snJ",
				function()
					require("dotmd").pick({
						type = "journal",
						grep = true,
					})
				end,
				mode = "n",
				desc = "[DotMd] Search journal grep",
				noremap = true,
			},
		},
	},
}
