return {
	{
		"nvim-treesitter/nvim-treesitter",
		version = false, -- last release is way too old and doesn't work on Windows
		lazy = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		build = ":TSUpdate",
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		init = function(plugin)
			-- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
			-- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
			-- no longer trigger the **nvim-treeitter** module to be loaded in time.
			-- Luckily, the only thins that those plugins need are the custom queries, which we make available
			-- during startup.
			require("lazy.core.loader").add_to_rtp(plugin)
			require("nvim-treesitter.query_predicates")
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			-- import nvim-treesitter plugin
			local treesitter = require("nvim-treesitter.configs")

			-- configure treesitter
			treesitter.setup({
				-- enable syntax highlighting
				highlight = {
					enable = true,
				},
				-- enable indentation
				indent = { enable = true },
				-- enable autotagging (w/ nvim-ts-autotag plugin)
				-- autotag = {
				-- 	enable = true,
				-- },
				-- ensure these language parsers are installed
				ensure_installed = {
					"bash",
					"comment",
					"css",
					"dockerfile",
					"git_config",
					"git_rebase",
					"gitcommit",
					"gitignore",
					"html",
					"javascript",
					"jsdoc",
					"json",
					"jsonc",
					"lua",
					"luadoc",
					"luap",
					"luau",
					"markdown",
					"markdown_inline",
					"nix",
					"pem",
					"prisma",
					"regex",
					"scss",
					"ssh_config",
					"toml",
					"tsx",
					"typescript",
					"xml",
					"vimdoc",
					"yaml",
				},
				query_linter = {
					enable = true,
					use_virtual_text = true,
					lint_events = { "BufWrite", "CursorHold" },
				},
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<C-space>",
						node_incremental = "<C-space>",
						scope_incremental = false,
						node_decremental = "<bs>",
					},
				},

				textobjects = {
					select = {
						enable = true,

						-- Automatically jump forward to textobj, similar to targets.vim
						lookahead = true,

						keymaps = {

							["aa"] = {
								query = "@assignment.outer",
								desc = "Select outer part of an assignment",
							},
							["ia"] = {
								query = "@assignment.inner",
								desc = "Select inner part of an assignment",
							},
							-- ["ll"] = {
							-- 	query = "@assignment.lhs",
							-- 	desc = "Select left hand side of an assignment",
							-- },
							-- ["rr"] = {
							-- 	query = "@assignment.rhs",
							-- 	desc = "Select right hand side of an assignment",
							-- },

							["ap"] = {
								query = "@parameter.outer",
								desc = "Select outer part of a parameter/argument",
							},
							["ip"] = {
								query = "@parameter.inner",
								desc = "Select inner part of a parameter/argument",
							},

							["ai"] = {
								query = "@conditional.outer",
								desc = "Select outer part of a conditional",
							},
							["ii"] = {
								query = "@conditional.inner",
								desc = "Select inner part of a conditional",
							},

							["al"] = {
								query = "@loop.outer",
								desc = "Select outer part of a loop",
							},
							["il"] = {
								query = "@loop.inner",
								desc = "Select inner part of a loop",
							},

							["af"] = {
								query = "@call.outer",
								desc = "Select outer part of a function call",
							},
							["if"] = {
								query = "@call.inner",
								desc = "Select inner part of a function call",
							},

							["am"] = {
								query = "@function.outer",
								desc = "Select outer part of a method/function definition",
							},
							["im"] = {
								query = "@function.inner",
								desc = "Select inner part of a method/function definition",
							},

							["ac"] = {
								query = "@class.outer",
								desc = "Select outer part of a class",
							},
							["ic"] = {
								query = "@class.inner",
								desc = "Select inner part of a class",
							},
						},
					},
				},
			})

			-- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
			require("ts_context_commentstring").setup({})

			-- MDX
			vim.filetype.add({
				extension = {
					mdx = "mdx",
				},
			})
			vim.treesitter.language.register("markdown", "mdx")
		end,
	},
}
