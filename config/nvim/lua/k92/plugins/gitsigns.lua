---@type LazySpec
return {
	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		---@module 'gitsigns'
		---@type Gitsigns.Config?
		---@diagnostic disable-next-line: missing-fields
		opts = {
			signs = {
				---@diagnostic disable-next-line: missing-fields
				add = { text = "▎" },
				---@diagnostic disable-next-line: missing-fields
				change = { text = "▎" },
				---@diagnostic disable-next-line: missing-fields
				delete = { text = "" },
				---@diagnostic disable-next-line: missing-fields
				topdelete = { text = "" },
				---@diagnostic disable-next-line: missing-fields
				changedelete = { text = "▎" },
				---@diagnostic disable-next-line: missing-fields
				untracked = { text = "▎" },
			},
			signs_staged = {
				---@diagnostic disable-next-line: missing-fields
				add = { text = "▎" },
				---@diagnostic disable-next-line: missing-fields
				change = { text = "▎" },
				---@diagnostic disable-next-line: missing-fields
				delete = { text = "" },
				---@diagnostic disable-next-line: missing-fields
				topdelete = { text = "" },
				---@diagnostic disable-next-line: missing-fields
				changedelete = { text = "▎" },
			},
			attach_to_untracked = true,
			preview_config = {
				border = "rounded",
			},
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

				map("n", "]h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gs.nav_hunk("next")
					end
				end, "Next Hunk")
				map("n", "[h", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gs.nav_hunk("prev")
					end
				end, "Prev Hunk")
				map("n", "]H", function()
					gs.nav_hunk("last")
				end, "Last Hunk")
				map("n", "[H", function()
					gs.nav_hunk("first")
				end, "First Hunk")
				map("n", "<leader>gp", gs.preview_hunk_inline, "Preview Hunk Inline")
				map("n", "<leader>gd", gs.diffthis, "Diff This")

				-- NOTE: Make heirline to load on attach. If not when open another file after enter the buffer,
				-- git branch will be empty and only loads in after interaction.
				vim.cmd("redrawstatus")
			end,
		},
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				gitsigns = true,
			},
		},
	},
}
