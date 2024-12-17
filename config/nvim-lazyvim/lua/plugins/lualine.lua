return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = function(_, opts)
		local catppuccin_palettes = require("catppuccin.palettes").get_palette()

		table.insert(opts.sections.lualine_c, 2, {
			"grapple",
			color = { fg = catppuccin_palettes.flamingo },
		})
	end,
}
