---@type LazySpec
return {
	{
		"y3owk1n/undo-glow.nvim",
		-- dir = "~/Dev/undo-glow.nvim", -- Your path
		event = { "VeryLazy" },
		---@type UndoGlow.Config
		opts = {
			undo_hl = "DiffDelete",
			redo_hl = "DiffAdd",
			duration = 1000,
		},
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
						undo_glow.attach_and_run({
							hlgroup = "UgUndo",
						})
					end)
				end,
			})
		end,
	},
}
