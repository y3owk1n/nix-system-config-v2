local find_root = require("k92.utils.file").find_root

return {
	"stevearc/conform.nvim",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	keys = { { "<leader>lc", "<cmd>ConformInfo<cr>", desc = "Conform Info" } },
	dependencies = { "mason.nvim" },
	opts = {
		format_on_save = {
			lsp_fallback = true,
			async = false,
			timeout_ms = 1000,
		},
		formatters = {
			biome = {
				---@diagnostic disable-next-line: unused-local
				condition = function(self, ctx)
					return find_root(ctx, { "biome.json" })
				end,
			},
		},
		formatters_by_ft = {
			lua = { "stylua" },
			sh = { "beautysh" },
			fish = { "fish_indent" },
			javascript = { { "biome", "prettierd" } },
			javascriptreact = { { "biome", "prettierd" } },
			typescript = { { "biome", "prettierd" } },
			typescriptreact = { { "biome", "prettierd" } },
			json = { { "biome", "prettierd" } },
			jsonc = { { "biome", "prettierd" } },
			markdown = { "prettierd" },
			["markdown.mdx"] = { "prettierd" },
			nix = { "nixfmt" },
			["*"] = { "codespell" },
			["_"] = { "trim_whitespace" },
		},
	},
}
