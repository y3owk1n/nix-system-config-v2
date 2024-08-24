local keymap = require("k92.utils.keymaps")
local map = keymap.map

return {
	"ThePrimeagen/harpoon",
	lazy = true,
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		settings = {
			save_on_toggle = true,
			sync_on_ui_close = true,
		},
		menu = {
			width = vim.api.nvim_win_get_width(0) - 4,
		},
	},
	config = function(_, opts)
		---@diagnostic disable-next-line: different-requires
		local harpoon = require("harpoon")
		harpoon:setup(opts)

		map("n", "<leader>he", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Harpoon Menu" })

		map("n", "<leader>ha", function()
			harpoon:list():add()
		end, { desc = "Mark file with harpoon" })

		map("n", "<leader>hc", function()
			harpoon:list():clear()
		end, { desc = "Clear all files in harpoon" })

		map("n", "<leader>h'", function()
			harpoon:list():select(1)
		end, { desc = "Harpoon #1" })

		map("n", "<leader>h,", function()
			harpoon:list():select(2)
		end, { desc = "Harpoon #2" })

		map("n", "<leader>h.", function()
			harpoon:list():select(3)
		end, { desc = "Harpoon #3" })

		map("n", "<leader>hp", function()
			harpoon:list():select(4)
		end, { desc = "Harpoon #4" })
	end,
}
