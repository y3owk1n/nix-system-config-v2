local _table = require("k92.utils.table")

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "markdown", "markdown_inline" })
			vim.filetype.add({
				extension = { mdx = "markdown.mdx" },
			})
			vim.treesitter.language.register("markdown", "markdown.mdx")
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters = {
				["markdown-toc"] = {
					condition = function(_, ctx)
						for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
							if line:find("<!%-%- toc %-%->") then
								return true
							end
						end
					end,
				},
				["markdownlint-cli2"] = {
					condition = function(_, ctx)
						local diag = vim.tbl_filter(function(d)
							return d.source == "markdownlint"
						end, vim.diagnostic.get(ctx.buf))
						return #diag > 0
					end,
				},
			},
			formatters_by_ft = {
				["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
				["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "markdownlint-cli2", "markdown-toc" })

			opts.servers = opts.servers or {}
			opts.servers.marksman = {}
		end,
	},
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				markdown = { "markdownlint-cli2" },
				["markdown.mdx"] = { "markdownlint-cli2" },
			},
		},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		opts = {
			code = {
				sign = false,
				width = "block",
				right_pad = 1,
			},
			heading = {
				sign = false,
				icons = {},
			},
		},
		ft = { "markdown", "markdown.mdx", "norg", "rmd", "org" },
		config = function(_, opts)
			require("render-markdown").setup(opts)
			Snacks.toggle({
				name = "Render Markdown",
				get = function()
					return require("render-markdown.state").enabled
				end,
				set = function(enabled)
					local m = require("render-markdown")
					if enabled then
						m.enable()
					else
						m.disable()
					end
				end,
			}):map("<leader>um")
		end,
	},
	{
		"catppuccin/nvim",
		optional = true,
		opts = {
			integrations = {
				markdown = true,
				render_markdown = true,
			},
		},
	},
}
