---@type LazySpec
return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		dependencies = { "mason.nvim" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({
						async = true,
						lsp_format = "fallback",
					})
				end,
				desc = "Format buffer",
			},
			{
				"<leader>ic",
				":ConformInfo<CR>",
				desc = "Conform Info",
			},
		},
		---@module "conform"
		---@type conform.setupOpts
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- Disable "format_on_save lsp_fallback" for languages that don't
				-- have a well standardized coding style. You can add additional
				-- languages here or re-enable it for the disabled ones.
				local disable_filetypes = { c = true, cpp = true }
				local lsp_format_opt
				if disable_filetypes[vim.bo[bufnr].filetype] then
					lsp_format_opt = "never"
				else
					lsp_format_opt = "fallback"
				end
				return {
					timeout_ms = 1000,
					lsp_format = lsp_format_opt,
				}
			end,
			formatters = {},
			formatters_by_ft = {},
		},
	},
}
