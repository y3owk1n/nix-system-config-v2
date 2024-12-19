return {
	"cbochs/grapple.nvim",
	event = "VeryLazy",
	opts = {
		scope = "git", -- also try out "git_branch"
		win_opts = {
			border = "rounded",
			footer = "",
		},
	},
	cmd = "Grapple",
	keys = function()
		local keys = {
			{
				"<leader>ha",
				"<cmd>Grapple toggle<cr>",
				desc = "Grapple File",
			},
			{
				"<leader>he",
				"<cmd>Grapple toggle_tags<cr>",
				desc = "Grapple Quick Menu",
			},
		}

		for i = 1, 5 do
			table.insert(keys, {
				"<leader>" .. i,
				"<cmd>Grapple select index=" .. i .. "<cr>",
				desc = "Grapple to File " .. i,
			})
		end
		return keys
	end,
}
