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
				lualine_a = {
					{
						"mode",
						fmt = function(string)
							local mode_names = {
								NORMAL = "N",
								["NORMAL-OPERATOR-PENDING"] = "N?",
								["NORMAL-OPERATOR-PENDING-VISUAL"] = "N?",
								["NORMAL-OPERATOR-PENDING-VISUAL-BLOCK"] = "N?",
								["NORMAL-OPERATOR-PENDING-VISUAL-CTRL-V"] = "N?",
								["NORMAL-INSERT"] = "Ni",
								["NORMAL-REPLACE"] = "Nr",
								["NORMAL-VISUAL"] = "Nv",
								["NORMAL-TERMINAL"] = "Nt",
								VISUAL = "V",
								["VISUAL-SELECT"] = "Vs",
								["V-LINE"] = "V_",
								["VISUAL-SELECT-LINE"] = "Vs",
								["VISUAL-CTRL-V"] = "^V",
								["VISUAL-CTRL-V-SELECT"] = "^V",
								SELECT = "S",
								["SELECT-LINE"] = "S_",
								["SELECT-CTRL-S"] = "^S",
								INSERT = "I",
								["INSERT-COMPLETION"] = "Ic",
								["INSERT-COMPLETION-FAIL"] = "Ix",
								REPLACE = "R",
								["REPLACE-COMPLETION"] = "Rc",
								["REPLACE-COMPLETION-FAIL"] = "Rx",
								["REPLACE-VISUAL"] = "Rv",
								["REPLACE-VISUAL-COMPLETION"] = "Rv",
								["REPLACE-VISUAL-COMPLETION-FAIL"] = "Rv",
								COMMAND = "C",
								["COMMAND-EX"] = "Ex",
								PROMPT = "...",
								["PROMPT-MORE"] = "M",
								["PROMPT-QUESTION"] = "?",
								["SHELL"] = "!",
								TERMINAL = "T",
							}

							return " " .. mode_names[string]
						end,
					},
				},
				lualine_b = {
					{
						"branch",
						icon = {
							"",
						},
					},
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
						"filename",
						path = 4,
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
								return "  ["
									.. table.concat(
										vim.tbl_map(function(client)
											return client.name
										end, clients),
										","
									)
									.. "] "
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
