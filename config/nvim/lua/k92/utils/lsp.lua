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

---@param cmd string[]
---@param on_done function(string[]?)
---@param on_error? function(integer, string[]?)
function M.run_async_job(cmd, on_done, on_error)
	local stdout = {}
	local stderr = {}

	local jobid = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data, _)
			data = table.concat(data, "\n")
			if #data > 0 then
				stdout[#stdout + 1] = data
			end
		end,
		on_stderr = function(_, data, _)
			stderr[#stderr + 1] = table.concat(data, "\n")
		end,
		on_exit = function(_, code, _)
			if code == 0 then
				on_done(stdout)
			else
				if on_error then
					on_error(code, stderr)
				else
					vim.notify(
						("[lspconfig] cmd failed with code %d: %s\n%s"):format(code, cmd, table.concat(stderr, "")),
						vim.log.levels.WARN
					)
				end
			end
		end,
		stdout_buffered = true,
		stderr_buffered = true,
	})

	if jobid <= 0 then
		vim.notify(("[lspconfig] unable to run cmd: %s"):format(cmd), vim.log.levels.WARN)
		return nil
	end
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

return M
