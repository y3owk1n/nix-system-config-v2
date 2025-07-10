local _table = require("k92.utils.table")

if not vim.g.has_node then
	return {}
end

---@alias ConformCtx {buf: number, filename: string, dirname: string}
local M = {}

local supported = {
	"css",
	"graphql",
	"handlebars",
	"html",
	"javascript",
	"javascriptreact",
	"json",
	"jsonc",
	"less",
	"markdown",
	"markdown.mdx",
	"scss",
	"typescript",
	"typescriptreact",
	"vue",
	"yaml",
}

--- Checks if a Prettier config file exists for the given context
---@param ctx ConformCtx
function M.has_config(ctx)
	vim.fn.system({ "prettierd", "--find-config-path", ctx.filename })
	return vim.v.shell_error == 0
end

--- Checks if a parser can be inferred for the given context:
--- * If the filetype is in the supported list, return true
--- * Otherwise, check if a parser can be inferred
---@param ctx ConformCtx
function M.has_parser(ctx)
	local ft = vim.bo[ctx.buf].filetype --[[@as string]]
	-- default filetypes are always supported
	if vim.tbl_contains(supported, ft) then
		return true
	end
	-- otherwise, check if a parser can be inferred
	local ret = vim.fn.system({ "prettierd", "--file-info", ctx.filename })
	---@type boolean, string?
	local ok, parser = pcall(function()
		return vim.fn.json_decode(ret).inferredParser
	end)
	return ok and parser and parser ~= vim.NIL
end

---@type LazySpec
return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}

			if vim.fn.executable("prettierd") == 0 then
				_table.add_unique_items(opts.ensure_installed, { "prettierd" })
			end
		end,
	},
	{
		"stevearc/conform.nvim",
		---@param opts conform.setupOpts
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			for _, ft in ipairs(supported) do
				opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
				table.insert(opts.formatters_by_ft[ft], "prettierd")
			end

			opts.formatters = opts.formatters or {}
			opts.formatters.prettierd = {
				condition = function(_, ctx)
					return M.has_parser(ctx) and (M.has_config(ctx))
				end,
			}
		end,
	},
}
