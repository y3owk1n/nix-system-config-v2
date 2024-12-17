local catppuccin_palettes = require('catppuccin.palettes').get_palette()

return {
	'nvim-lualine/lualine.nvim',
	event = 'VeryLazy',
	init = function()
		vim.g.lualine_laststatus = vim.o.laststatus
		if vim.fn.argc(-1) > 0 then
			-- set an empty statusline till lualine loads
			vim.o.statusline = ' '
		else
			-- hide the statusline on the starter page
			vim.o.laststatus = 0
		end
	end,
	opts = function()
		-- PERF: we don't need this lualine require madness 🤷
		local lualine_require = require 'lualine_require'
		lualine_require.require = require

		vim.o.laststatus = vim.g.lualine_laststatus

		local opts = {
			options = {
				icons_enabled = true,
				theme = 'auto',
				globalstatus = vim.o.laststatus == 3,
				component_separators = { left = '', right = '' },
				section_separators = { left = '', right = '' },
				disabled_filetypes = {
					statusline = { 'snacks_dashboard' },
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				always_show_tabline = true,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { 'mode' },
				lualine_b = { 'branch', 'diff', 'diagnostics' },
				lualine_c = {
					'filename',
					{
						'grapple',
						color = { fg = catppuccin_palettes.flamingo },
					},
				},
				lualine_x = { 'encoding', 'fileformat', 'filetype' },
				lualine_y = { 'progress' },
				lualine_z = { 'location' },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { 'filename' },
				lualine_x = { 'location' },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = { 'lazy' },
		}

		return opts
	end,
}
