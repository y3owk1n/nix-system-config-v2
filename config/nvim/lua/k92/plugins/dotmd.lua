---@type LazySpec
return {
	{
		"y3owk1n/dotmd.nvim",
		-- dir = "~/Dev/dotmd.nvim", -- Your path
		cmd = {
			"DotMdCreateNote",
			"DotMdCreateTodoToday",
			"DotMdCreateJournal",
			"DotMdInbox",
			"DotMdNavigate",
			"DotMdPick",
			"DotMdOpen",
		},
		event = "VeryLazy",
		---@type DotMd.Config
		opts = {
			root_dir = "~/Library/Mobile Documents/com~apple~CloudDocs/Cloud Notes",
			-- root_dir = "~/dotmd",
			default_split = "vertical",
			rollover_todo = {
				enabled = true,
			},
			picker = "snacks",
		},
		keys = {
			{
				"<leader>n",
				"",
				mode = "n",
				desc = "+dotmd",
			},
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
				"<leader>no",
				function()
					require("dotmd").open({
						pluralise_query = true,
					})
				end,
				mode = "n",
				desc = "[DotMd] Open",
				noremap = true,
			},
			{
				"<leader>sn",
				"",
				mode = "n",
				desc = "+dotmd",
			},
			{
				"<leader>sna",
				function()
					require("dotmd").pick()
				end,
				mode = "n",
				desc = "[DotMd] Search everything",
				noremap = true,
			},
			{
				"<leader>snA",
				function()
					require("dotmd").pick({
						grep = true,
					})
				end,
				mode = "n",
				desc = "[DotMd] Search everything grep",
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
						type = "journals",
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
						type = "journals",
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
