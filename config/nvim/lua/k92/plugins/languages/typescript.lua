local _table = require("k92.utils.table")


local filetypes = {
	"javascript",
	"javascriptreact",
	"javascript.jsx",
	"typescript",
	"typescriptreact",
	"typescript.tsx",
}
vim.lsp.enable("vtsls")

---@type LazySpec
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"javascript",
				"jsdoc",
				"tsx",
				"typescript",
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			_table.add_unique_items(opts.ensure_installed, { "vtsls" })
		end,
	},
	-- Filetype icons
	{
		"echasnovski/mini.icons",
		opts = {
			file = {
				[".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
				[".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
				[".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
				[".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
				["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
				["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
				["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
				["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
				["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
			},
		},
	},
	{
		"dmmulroy/ts-error-translator.nvim",
		ft = filetypes,
		opts = {},
	},
}
