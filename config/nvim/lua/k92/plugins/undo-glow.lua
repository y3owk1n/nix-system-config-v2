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
				opts.undo_hl_color = { bg = colors.maroon }
				opts.redo_hl_color = { bg = colors.teal }
			end
		end,
		---@param _ any
		---@param opts UndoGlow.Config
		config = function(_, opts)
			local undo_glow = require("undo-glow")

			undo_glow.setup(opts)

			vim.keymap.set("n", "U", "<C-r>", { noremap = true, silent = true })

			vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged" }, {
				pattern = "*",
				callback = function()
					if vim.bo.buftype ~= "" then
						return
					end

					vim.schedule(function()
						require("undo-glow").attach_and_run({
							hlgroup = "UgUndo",
						})
					end)
				end,
			})
		end,
	},
}
