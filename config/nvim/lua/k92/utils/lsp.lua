local M = {}

local iswin = vim.uv.os_uname().version:match("Windows")

function M.tbl_flatten(t)
	--- @diagnostic disable-next-line:deprecated
	return vim.iter(t):flatten(math.huge):totable() or vim.tbl_flatten(t)
end

function M.strip_archive_subpath(path)
	-- Matches regex from zip.vim / tar.vim
	path = vim.fn.substitute(path, "zipfile://\\(.\\{-}\\)::[^\\\\].*$", "\\1", "")
	path = vim.fn.substitute(path, "tarfile:\\(.\\{-}\\)::.*$", "\\1", "")
	return path
end

function M.search_ancestors(startpath, func)
	vim.validate("func", func, "function")
	if func(startpath) then
		return startpath
	end
	local guard = 100
	for path in vim.fs.parents(startpath) do
		-- Prevent infinite recursion if our algorithm breaks
		guard = guard - 1
		if guard == 0 then
			return
		end

		if func(path) then
			return path
		end
	end
end

function M.escape_wildcards(path)
	return path:gsub("([%[%]%?%*])", "\\%1")
end

function M.root_pattern(...)
	local patterns = M.tbl_flatten({ ... })
	return function(startpath)
		startpath = M.strip_archive_subpath(startpath)
		for _, pattern in ipairs(patterns) do
			local match = M.search_ancestors(startpath, function(path)
				for _, p in ipairs(vim.fn.glob(table.concat({ M.escape_wildcards(path), pattern }, "/"), true, true)) do
					if vim.uv.fs_stat(p) then
						return path
					end
				end
			end)

			if match ~= nil then
				return match
			end
		end
	end
end

function M.decode_json_file(filename)
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

function M.has_nested_key(json, ...)
	return vim.tbl_get(json, ...) ~= nil
end

function M.insert_package_json(config_files, field, fname)
	local path = vim.fn.fnamemodify(fname, ":h")
	local root_with_package = vim.fs.dirname(vim.fs.find("package.json", { path = path, upward = true })[1])

	if root_with_package then
		-- only add package.json if it contains field parameter
		local path_sep = iswin and "\\" or "/"
		for line in io.lines(root_with_package .. path_sep .. "package.json") do
			if line:find(field) then
				config_files[#config_files + 1] = "package.json"
				break
			end
		end
	end
	return config_files
end

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
function M.execute(opts)
	local params = {
		command = opts.command,
		arguments = opts.arguments,
	}
	if opts.open then
		require("trouble").open({
			mode = "lsp_command",
			params = params,
		})
	else
		return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
	end
end

M.action = setmetatable({}, {
	__index = function(_, action)
		return function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					only = { action },
					diagnostics = {},
				},
			})
		end
	end,
})

function M.map(bufnr, keys, func, desc, mode)
	mode = mode or "n"
	vim.keymap.set(mode, keys, func, {
		buffer = bufnr,
		silent = true,
		desc = "LSP: " .. desc,
	})
end

---@param config vim.lsp.Config
---@param bufnr integer
function M.start_config(config, bufnr)
	config = vim.deepcopy(config)

	if type(config.root_dir) == "function" then
		---@param root_dir string
		config.root_dir(bufnr, function(root_dir)
			config.root_dir = root_dir
			vim.schedule(function()
				vim.lsp.start(config, {
					bufnr = bufnr,
					reuse_client = config.reuse_client,
					_root_markers = config.root_markers,
				})
			end)
		end)
	else
		vim.lsp.start(config, {
			bufnr = bufnr,
			reuse_client = config.reuse_client,
			_root_markers = config.root_markers,
		})
	end
end

return M
