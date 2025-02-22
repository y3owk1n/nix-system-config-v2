local function decode_json_file(filename)
	local file = io.open(filename, "r")
	if file then
		local content = file:read("*all")
		file:close()

		local ok, data = pcall(vim.fn.json_decode, content)
		if ok and type(data) == "table" then
			return data
		end
	end
end

local function has_nested_key(json, ...)
	return vim.tbl_get(json, ...) ~= nil
end

---@type LazySpec
return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			local root_pattern = require("lspconfig.util").root_pattern
			opts.servers = opts.servers or {}
			opts.servers.tailwindcss = function() end
			opts.servers.tailwindcss = {
				-- NOTE: Override unique root pattern with custom checks
				-- Current state, it doesn't work for monorepo, since v4 does not have any config anymore
				-- To cover the use cases of v3 and v4, the following checks are being made for now with an
				-- assumption of if package.json has tailwindcss installed, the LSP should be activated
				--   1. Get the git root (as workspace root)
				--   2. Get the nearest package.json (relative to current file)
				--   3. Try to find if there's any tailwindcss package installed in the package.json
				--   4. If yes, then return the git root (so that it can detect nested css from other packages within
				--      the workspace)
				root_dir = function(fname)
					local git_root = root_pattern(".git")(fname)

					local package_root = root_pattern("package.json")(fname)

					if package_root and git_root then
						local package_data = decode_json_file(package_root .. "/package.json")
						if
							package_data
							and (
								has_nested_key(package_data, "dependencies", "tailwindcss")
								or has_nested_key(package_data, "devDependencies", "tailwindcss")
							)
						then
							return git_root
						end
					end
				end,
			}
		end,
	},
	{
		"y3owk1n/tailwind-autosort.nvim",
		-- dir = "~/Dev/tailwind-autosort.nvim", -- Your path
		version = "*",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		---@type TailwindAutoSort.Config
		opts = {},
	},
}
