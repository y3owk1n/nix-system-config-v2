local _table = require("k92.utils.table")

local M = {}

-- Internal cache table
local cache = {}

-- Set context for tools
local tools = {}

local fallbacks = {
	biome = "biome",
	prettier = "prettierd",
}

-- Safe path join
local function join(...)
	local args = { ... }
	local result = args[1]:gsub("/+$", "")
	for i = 2, #args do
		local part = args[i]:gsub("^/+", ""):gsub("/+$", "")
		result = result .. "/" .. part
	end
	return vim.fs.normalize(result)
end

---@param path string path to check
---@return boolean
local function is_executable(path)
	return vim.fn.filereadable(path) == 1 and vim.fn.executable(path) == 1
end

---@param tool string tool name to resolve, e.g. `biome`
---@param start_path string start path to search from
---@return string? path to the tool, or nil if not found
---@return string? root path of the tool, or nil if not found
local function find_nearest_executable(tool, start_path)
	local dir = vim.fn.fnamemodify(start_path, ":p"):gsub("/+$", "")

	while dir and dir ~= "/" do
		local candidate = join(dir, "node_modules", ".bin", tool)
		if is_executable(candidate) then
			return candidate, dir
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end -- safety: don't loop forever
		dir = parent:gsub("/+$", "") -- normalize again
	end

	return nil, nil
end

---@param tool string tool name to add, e.g. `biome`
function M.add_tool(tool)
	_table.add_unique_items(tools, { tool })
end

function M.get_tools()
	return tools
end

---@class ToolResolverOpts
---@field path? string start search path (default: current buffer)

-- Resolving tools for `node_modules`. Mainly used for tools like `biome` that will break when the lsp version is different
-- than the project installed version in `node_modules`. The tool will try to resolve the binary from the current buffer to
-- the node modules available binary, and only fallback to the globally installed version.
---@param tool string
---@param opts? ToolResolverOpts
---@return string
function M.get(tool, opts)
	opts = opts or {}

	-- Get buffer path (default to current buffer)
	local buf_path = opts.path or vim.api.nvim_buf_get_name(0)
	if buf_path == "" then
		buf_path = vim.fn.getcwd()
	end

	local fallback = fallbacks[tool]

	if not fallback then
		fallback = tool
	end

	-- Try from buffer path
	local bin, root = find_nearest_executable(tool, buf_path)

	-- Try from CWD if not found
	if not bin then
		bin, root = find_nearest_executable(tool, vim.fn.getcwd())
	end

	local cache_key = (root or "__NO_ROOT__") .. "::" .. tool

	if cache[cache_key] then
		return cache[cache_key]
	end

	-- Cache result
	if bin then
		cache[cache_key] = bin
		return bin
	end

	cache[cache_key] = fallback
	return fallback
end

-- Manual cache clear
function M.clear_cache()
	cache = {}
end

function M.setup_usercmds()
	-- Command: :ToolResolverGet biome
	vim.api.nvim_create_user_command("ToolResolverGet", function(opts)
		local tool = opts.args
		local path = vim.api.nvim_buf_get_name(0)
		local resolved = M.get(tool, { path = path })
		vim.notify(("Resolved tool '%s': %s"):format(tool, resolved))
	end, {
		nargs = 1,
		complete = function(arg)
			return vim.iter(M.get_tools())
				:map(function(tool)
					return tool
				end)
				:filter(function(tool)
					return tool:sub(1, #arg) == arg
				end)
				:totable()
		end,
	})

	-- Command: :ToolResolverClearCache
	vim.api.nvim_create_user_command("ToolResolverClearCache", function()
		M.clear_cache()
		vim.notify("Cache cleared")
	end, {})

	-- Command: :ToolResolverGetCache
	vim.api.nvim_create_user_command("ToolResolverGetCache", function()
		vim.notify(vim.inspect(cache))
	end, {})
end

function M.setup_autocmds()
	-- Auto-clear on DirChanged
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			M.clear_cache()
		end,
	})

	-- Auto-resolve per-buffer switch
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			local path = vim.api.nvim_buf_get_name(args.buf)

			for _, tool in ipairs(M.get_tools()) do
				M.get(tool, { path = path })
			end
		end,
	})
end

return M
