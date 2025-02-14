---@type LazySpec
return {
	{
		"y3owk1n/undo-glow.nvim",
		-- dir = "~/Dev/undo-glow.nvim", -- Your path
		event = { "VeryLazy" },
		---@param _ any
		---@param opts UndoGlow.Config
		opts = function(_, opts)
			local has_catppuccin, catppuccin = pcall(require, "catppuccin.palettes")

			if has_catppuccin then
				local colors = catppuccin.get_palette()
				opts.undo_hl_color = { bg = colors.red, fg = colors.base }
				opts.redo_hl_color = { bg = colors.flamingo, fg = colors.base }
			end
		end,
		---@param _ any
		---@param opts UndoGlow.Config
		config = function(_, opts)
			local undo_glow = require("undo-glow")

			undo_glow.setup(opts)

			vim.keymap.set("n", "u", undo_glow.undo, { noremap = true, silent = true })
			vim.keymap.set("n", "U", undo_glow.redo, { noremap = true, silent = true })
		end,
	},
}
