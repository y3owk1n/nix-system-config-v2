local _table = require("k92.utils.table")

if not vim.g.has_node then
	return {}
end

vim.lsp.enable("tailwindcss")

---@type LazySpec
return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}

			if vim.fn.executable("tailwindcss-language-server") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "tailwindcss-language-server" })
			end
		end,
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		-- version = "*",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		init = function()
			local allowed_clients = { "tailwindcss" }

			require("k92.utils.lazy").lazy_load_lsp_attach(allowed_clients, "tailwind-autosort.nvim")
		end,
		---@module "tailwind-autosort"
		---@type TailwindAutoSort.Config
		opts = {},
	},
}
