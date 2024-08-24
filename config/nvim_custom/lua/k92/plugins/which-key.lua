return {
	"folke/which-key.nvim",
	lazy = true,
	event = "VeryLazy",

	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 500
	end,
	opts = {
		preset = "modern",
		win = {
			border = "rounded", -- none, single, double, shadow
		},
		spec = {
			{
				-- Nested mappings are allowed and can be added in any order
				-- Most attributes can be inherited or overridden on any level
				-- There's no limit to the depth of nesting
				mode = { "n", "v" }, -- NORMAL and VISUAL mode
				{ "g", desc = "+goto" }, -- no need to specify mode since it's inherited
				{ "gs", desc = "+surround" }, -- no need to specify mode since it's inherited
				{ "]", desc = "+next" }, -- no need to specify mode since it's inherited
				{ "[", desc = "+prev" }, -- no need to specify mode since it's inherited
				{ "<leader>c", desc = "+[c]ode" }, -- no need to specify mode since it's inherited
				{ "<leader>l", desc = "+[l]sp" }, -- no need to specify mode since it's inherited
				{ "<leader>lb", desc = "+[l]sp [b]uiltin" }, -- no need to specify mode since it's inherited
				{ "<leader>f", desc = "+[f]ile" }, -- no need to specify mode since it's inherited
				{ "<leader>g", desc = "+[g]it" }, -- no need to specify mode since it's inherited
				{ "<leader>h", desc = "+[h]arpoon" }, -- no need to specify mode since it's inherited
				{ "<leader>s", desc = "+[s]earch" }, -- no need to specify mode since it's inherited
				{ "<leader>w", desc = "+[w]indows" }, -- no need to specify mode since it's inherited
				{ "<leader>x", desc = "+[t]rouble" }, -- no need to specify mode since it's inherited
			},
		},
		-- defaults = {
		-- 	mode = { "n", "v" },
		-- 	["g"] = { name = "+goto" },
		-- 	["gs"] = { name = "+surround" },
		-- 	["]"] = { name = "+next" },
		-- 	["["] = { name = "+prev" },
		-- 	["<leader>c"] = { name = "+[c]ode" },
		-- 	["<leader>l"] = { name = "+[l]sp" },
		-- 	["<leader>lb"] = { name = "+[l]sp [b]uiltin" },
		-- 	["<leader>f"] = { name = "+[f]ile" },
		-- 	["<leader>g"] = { name = "+[g]it" },
		-- 	["<leader>h"] = { name = "+[h]arpoon" },
		-- 	["<leader>s"] = { name = "+[s]earch" },
		-- 	["<leader>w"] = { name = "+[w]indows" },
		-- 	["<leader>x"] = { name = "+[t]rouble" },
		-- },
	},
}
