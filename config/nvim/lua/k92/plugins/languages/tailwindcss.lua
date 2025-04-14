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
			_table.add_unique_items(opts.ensure_installed, { "tailwindcss-language-server" })
		end,
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		-- version = "*",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		init = function()
			local augroup = require("k92.utils.autocmds").augroup

			vim.api.nvim_create_autocmd("LspAttach", {
				group = augroup("lsp_tailwind-autosort_attach"),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client.name == "tailwindcss" then
						require("lazy").load({ plugins = { "tailwind-autosort.nvim" } })
					end
				end,
			})
		end,
		---@module "tailwind-autosort"
		---@type TailwindAutoSort.Config
		opts = {},
	},
}
