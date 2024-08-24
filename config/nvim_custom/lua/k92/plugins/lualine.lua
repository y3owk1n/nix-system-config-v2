return {
	"nvim-lualine/lualine.nvim",
	lazy = true,
	event = { "VeryLazy" }, -- to disable, comment this out
	dependencies = { "nvim-tree/nvim-web-devicons" },
	init = function()
		vim.g.lualine_laststatus = vim.o.laststatus
		if vim.fn.argc(-1) > 0 then
			-- set an empty statusline till lualine loads
			vim.o.statusline = " "
		else
			-- hide the statusline on the starter page
			vim.o.laststatus = 0
		end
	end,
	config = function()
		-- PERF: we don't need this lualine require madness 🤷
		local lualine_require = require("lualine_require")
		lualine_require.require = require

		local lualine = require("lualine")
		local lazy_status = require("lazy.status") -- to configure lazy pending updates count
		local catppuccin_palettes = require("catppuccin.palettes").get_palette()

		local buffer_utils = require("k92.utils.buffer")
		local startup_util = require("k92.utils.startup")
		---@diagnostic disable-next-line: different-requires
		local harpoon_util = require("k92.utils.harpoon")

		vim.o.laststatus = vim.g.lualine_laststatus

		local function mode_icon()
			return " " .. "" .. " "
		end

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = "catppuccin",
				globalstatus = true,
				disabled_filetypes = {
					statusline = { "dashboard", "alpha", "starter" },
				},
				component_separators = {
					left = " ",
					right = " ",
				},
				section_separators = {
					left = "",
					right = "",
				},
			},
			sections = {
				lualine_a = {
					{
						mode_icon,
						padding = { left = 0, right = 0 },
					},
				},
				lualine_b = {
					{ "branch", icon = "" },
					{
						"diff",
						symbols = {
							added = " ",
							modified = " ",
							removed = " ",
						},
					},
				},
				lualine_c = {
					{
						harpoon_util.show_harpoon_component,
						color = { fg = catppuccin_palettes.flamingo },
					},
					{
						"filename",
						path = 1,
					},
					{
						"diagnostics",
						symbols = {
							error = " ",
							warn = " ",
							info = " ",
							hint = " ",
						},
					},
				},
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = catppuccin_palettes.flamingo },
					},
					{
						startup_util.show_startuptime,
						color = {
							fg = catppuccin_palettes.rosewater,
						},
					},
					{
						"filetype",
						icon_only = true,
						separator = "",
						padding = { left = 1, right = 2 },
					},
				},
			},
			extensions = { "lazy", "mason", "neo-tree", "quickfix", "trouble" },
		})
	end,
}
