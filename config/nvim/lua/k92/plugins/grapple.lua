return {
	"cbochs/grapple.nvim",
	event = "VeryLazy",
	opts = {
		statusline = {
			icon = "󱡁",
		},
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

		local tags = require("grapple").tags()

		if #tags > 0 then
			for i = 1, #tags do
				table.insert(keys, {
					"<leader>" .. i,
					"<cmd>Grapple select index=" .. i .. "<cr>",
					desc = "Grapple to File " .. i,
				})
			end
		end

		return keys
	end,
	config = function(_, opts)
		require("grapple").setup(opts)

		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("k92_" .. "update_grapple_keymap", { clear = true }),
			pattern = "GrappleUpdate",
			callback = function()
				-- Clear existing mappings first and silent the error
				for i = 1, 9 do
					pcall(vim.keymap.del, "n", "<leader>" .. i)
				end

				-- Set new mappings, limited to 9
				local tags = require("grapple").tags()
				local num_tags = math.min(#tags, 9)

				for i = 1, num_tags do
					vim.keymap.set(
						"n",
						"<leader>" .. i,
						"<cmd>Grapple select index=" .. i .. "<cr>",
						{ desc = "Grapple to File " .. i }
					)
				end
			end,
		})
	end,
}
