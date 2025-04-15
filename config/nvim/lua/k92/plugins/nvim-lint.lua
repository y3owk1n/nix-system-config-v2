---@type LazySpec
return {
	"mfussenegger/nvim-lint",
	event = { "BufWritePost", "BufReadPost", "InsertLeave" },
	opts = {
		events = { "BufWritePost", "BufReadPost", "InsertLeave" },
		linters_by_ft = {},
		linters = {},
	},
	keys = {
		{ "<leader>it", ":LintInfo<CR>", desc = "Lint info" },
	},
	config = function(_, opts)
		local M = {}

		local lint = require("lint")
		for name, linter in pairs(opts.linters) do
			if type(linter) == "table" and type(lint.linters[name]) == "table" then
				lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
				if type(linter.prepend_args) == "table" then
					lint.linters[name].args = lint.linters[name].args or {}
					vim.list_extend(lint.linters[name].args, linter.prepend_args)
				end
			else
				lint.linters[name] = linter
			end
		end
		lint.linters_by_ft = opts.linters_by_ft

		function M.lint()
			-- Use nvim-lint's logic first:
			-- * checks if linters exist for the full filetype first
			-- * otherwise will split filetype by "." and add all those linters
			-- * this differs from conform.nvim which only uses the first filetype that has a formatter
			local names = lint._resolve_linter_by_ft(vim.bo.filetype)

			-- Create a copy of the names table to avoid modifying the original.
			names = vim.list_extend({}, names)

			-- Add fallback linters.
			if #names == 0 then
				vim.list_extend(names, lint.linters_by_ft["_"] or {})
			end

			-- Add global linters.
			vim.list_extend(names, lint.linters_by_ft["*"] or {})

			-- Filter out linters that don't exist or don't match the condition.
			local ctx = { filename = vim.api.nvim_buf_get_name(0) }
			ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
			names = vim.tbl_filter(function(name)
				local linter = lint.linters[name]
				if not linter then
					vim.notify("Linter not found: " .. name)
				end
				return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
			end, names)

			-- Run linters.
			if #names > 0 then
				lint.try_lint(names)
			end
		end

		vim.api.nvim_create_autocmd(opts.events, {
			group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
			callback = require("k92.utils.debounce").debounce(100, M.lint),
		})

		vim.api.nvim_create_user_command("LintInfo", function()
			local filetype = vim.bo.filetype
			local lint_ok, _lint = pcall(require, "lint")

			local message = {}

			table.insert(message, "**Filetype:** `" .. filetype .. "`")
			table.insert(message, "")
			table.insert(message, "---")
			table.insert(message, "")

			if not lint_ok then
				table.insert(message, "❌ `nvim-lint` module not found. Please ensure it is installed and configured.")
			else
				local linters = _lint.linters_by_ft[filetype]

				if linters and #linters > 0 then
					table.insert(message, "- 🔍 **Number of Linters:** `" .. #linters .. "`")
					table.insert(message, "- 📦 **Available Linters:**")
					table.insert(message, "")
					for _, linter in ipairs(linters) do
						table.insert(message, "  - `" .. linter .. "`")
					end
				else
					table.insert(message, "⚠️ No linters configured for this filetype.")
				end
			end

			table.insert(message, "")
			table.insert(message, "_Press `q` to close this window_")

			Snacks.win({
				title = "Lint Information",
				title_pos = "center",
				text = message,
				ft = "markdown",
				width = 0.5,
				height = 0.3,
				position = "float",
				border = "rounded",
				minimal = true,
				wo = {
					spell = false,
					wrap = false,
					signcolumn = "yes",
					statuscolumn = " ",
					conceallevel = 3,
				},
				bo = {
					readonly = true,
					modifiable = false,
				},
				keys = {
					q = "close",
				},
			})
		end, {
			desc = "Display configured linters for the current filetype",
		})
	end,
}
