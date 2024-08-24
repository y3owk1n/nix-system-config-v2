local find_root = require("utils.file").find_root

return {
	"stevearc/conform.nvim",
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- log_level = vim.log.levels.INFO,
		formatters = {
			biome = {
				---@diagnostic disable-next-line: unused-local
				condition = function(self, ctx)
					return find_root(ctx, { "biome.json", "biome.jsonc" })
				end,
			},
			prettier = {
				---@diagnostic disable-next-line: unused-local
				condition = function(self, ctx)
					local prettier_configs = {
						".prettierrc",
						".prettierrc.json",
						".prettierrc.yml",
						".prettierrc.yaml",
						".prettierrc.json5",
						".prettierrc.js",
						"prettier.config.js",
						".prettierrc.mjs",
						"prettier.config.mjs",
						".prettierrc.cjs",
						"prettier.config.cjs",
						".prettierrc.toml",
						"package.json",
					}

					local root = find_root(ctx, prettier_configs)

					-- If want to be strict on prettier, uncomment the following
					-- to make sure prettier never runs without prettier key in package.json
					-- if root ~= "package.json" then
					--   local find_text_in_file = require("utils.file").find_text_in_file
					--   local has_prettier = find_text_in_file("prettier", root)
					--   if has_prettier > 0 then
					--     return true
					--   else
					--     return false
					--   end
					-- end
					--
					return root
				end,
			},
		},
		formatters_by_ft = {
			javascript = { "biome", "prettier", stop_after_first = true },
			javascriptreact = { "biome", "prettier", stop_after_first = true },
			typescript = { "biome", "prettier", stop_after_first = true },
			typescriptreact = { "biome", "prettier", stop_after_first = true },
			json = { "biome", "prettier", stop_after_first = true },
			jsonc = { "biome", "prettier", stop_after_first = true },
			css = { "prettier" },
		},
	},
}
