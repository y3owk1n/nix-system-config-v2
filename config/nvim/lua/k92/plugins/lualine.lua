return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
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
	opts = function()
		local catppuccin_palettes = require("catppuccin.palettes").get_palette()
		-- PERF: we don't need this lualine require madness 🤷
		local lualine_require = require("lualine_require")
		lualine_require.require = require

		vim.o.laststatus = vim.g.lualine_laststatus

		local opts = {
			options = {
				icons_enabled = true,
				theme = "catppuccin",
				globalstatus = vim.o.laststatus == 3,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = { "snacks_dashboard" },
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
				lualine_a = { "mode" },
				lualine_b = {
					"branch",
					{
						"diff",
						symbols = {
							added = " ",
							modified = " ",
							removed = " ",
						},
						source = function()
							local gitsigns = vim.b.gitsigns_status_dict
							if gitsigns then
								return {
									added = gitsigns.added,
									modified = gitsigns.changed,
									removed = gitsigns.removed,
								}
							end
						end,
					},
				},
				lualine_c = {
					{
						function()
							local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
							local fpath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.:h")
							local fname = vim.fn.expand("%:t")

							if fpath == "" or fpath == "." then
								return string.format(" %s/", cwd)
							end

							-- Split the file path into components
							local path_components = vim.split(fpath, "/", { plain = true })

							-- Determine whether to add "..."
							local path_depth = #path_components
							local display_path

							if path_depth > 1 then
								display_path = "~/" .. path_components[path_depth]
							else
								display_path = path_components[1]
							end

							local function read_only()
								if vim.bo.readonly then
									return ""
								end
								if vim.bo.modifiable == false then
									return ""
								end
								if vim.bo.modified then
									return ""
								end
								return ""
							end

							return string.format("%s/%s/%s %s", cwd, display_path, fname or "", read_only())
						end,
					},
					{
						"diagnostics",
						symbols = {
							error = " ",
							warn = " ",
							info = " ",
							hint = " ",
						},
					},
				},
				lualine_x = {
					{
						"grapple",
						color = { fg = catppuccin_palettes.flamingo },
					},
					{
						function()
							local clients = vim.lsp.get_clients({ bufnr = 0 })
							if #clients > 0 then
								return " "
									.. table.concat(
										vim.tbl_map(function(client)
											return client.name
										end, clients),
										","
									)
									.. " "
							end
							return ""
						end,
					},
				},
				lualine_y = { "filetype" },
				lualine_z = { "progress" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {
				"lazy",
				"fzf",
				"man",
				"mason",
				"quickfix",
				"trouble",
			},
		}

		return opts
	end,
}
