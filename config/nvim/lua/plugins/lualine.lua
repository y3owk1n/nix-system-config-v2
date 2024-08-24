return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = function(_, opts)
		local catppuccin_palettes = require("catppuccin.palettes").get_palette()
		local harpoon_util = require("utils.harpoon")

		table.insert(opts.sections.lualine_c, 2, {
			harpoon_util.show_harpoon_component,
			color = { fg = catppuccin_palettes.flamingo },
		})
	end,
}
