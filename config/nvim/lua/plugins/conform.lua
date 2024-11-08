local find_root = require("utils.file").find_root
local find_root_string = require("utils.file").find_root_string

return {
	"stevearc/conform.nvim",
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- log_level = vim.log.levels.INFO,
		formatters = {
			["biome-check"] = {
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
						-- "package.json",
					}

					local hasRoot = find_root(ctx, prettier_configs)

					if hasRoot == false then
						local root_string =
							find_root_string(ctx, { "package.json" })

						-- If want to be strict on prettier, uncomment the following
						-- to make sure prettier never runs without prettier key in package.json
						if root_string ~= "package.json" then
							local find_text_in_file =
								require("utils.file").find_text_in_file
							local has_prettier =
								find_text_in_file("prettier", root_string)

							return has_prettier > 0
						end

						return hasRoot
					end

					return hasRoot
				end,
			},
		},
		formatters_by_ft = {
			javascript = { "biome-check", "prettier", stop_after_first = true },
			javascriptreact = {
				"biome-check",
				"prettier",
				stop_after_first = true,
			},
			typescript = { "biome-check", "prettier", stop_after_first = true },
			typescriptreact = {
				"biome-check",
				"prettier",
				stop_after_first = true,
			},
			json = { "biome-check", "prettier", stop_after_first = true },
			jsonc = { "biome-check", "prettier", stop_after_first = true },
			css = { "prettier" },
		},
	},
}
