local augroup = require("k92.utils.autocmds").augroup
local info_buffer = require("k92.utils.info-buffer")

vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	virtual_text = true,
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
		},
	},
	float = {
		source = true,
		severity_sort = true,
	},
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(event)
		local map = require("k92.utils.lsp").map

		map(event.buf, "<leader>il", ":LspInfo<cr>", "Lsp Info")

		map(event.buf, "grs", vim.lsp.buf.signature_help, "Signature help")

		map(event.buf, "<leader>lr", ":LspRestart<cr>", "Restart all LSP")
		map(event.buf, "<leader>ll", ":LspLog<cr>", "Log")
		map(event.buf, "<leader>li", ":LspInfo<cr>", "Lsp Info")
		map(event.buf, "<leader>lx", ":LspClearLog<cr>", "Clear Log")
	end,
})

---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
local progress = vim.defaulttable()
vim.api.nvim_create_autocmd("LspProgress", {
	group = augroup("lsp_progress"),
	---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
		if not client or type(value) ~= "table" then
			return
		end
		local p = progress[client.id]

		for i = 1, #p + 1 do
			if i == #p + 1 or p[i].token == ev.data.params.token then
				p[i] = {
					token = ev.data.params.token,
					msg = ("[%3d%%] %s%s"):format(
						value.kind == "end" and 100 or value.percentage or 100,
						value.title or "",
						value.message and (" **%s**"):format(value.message) or ""
					),
					done = value.kind == "end",
				}
				break
			end
		end

		local msg = {} ---@type string[]
		progress[client.id] = vim.tbl_filter(function(v)
			return table.insert(msg, v.msg) or not v.done
		end, p)

		local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
		vim.notify(table.concat(msg, "\n"), vim.diagnostic.severity.INFO, {
			id = "lsp_progress",
			title = client.name,
			opts = function(notif)
				notif.icon = #progress[client.id] == 0 and " "
					or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
			end,
		})
	end,
})

local complete_client = function(arg)
	return vim.iter(vim.lsp.get_clients())
		:map(function(client)
			return client.name
		end)
		:filter(function(name)
			return name:sub(1, #arg) == arg
		end)
		:totable()
end

local complete_config = function(arg)
	return vim.iter(vim.tbl_keys(vim.lsp._enabled_configs))
		:filter(function(name)
			return name:sub(1, #arg) == arg
		end)
		:totable()
end

vim.api.nvim_create_user_command("LspRestart", function(info)
	local clients = {}

	if #info.fargs == 0 then
		clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
	else
		clients = vim.iter(info.fargs)
			:map(function(name)
				local client = vim.lsp.get_clients({ name = name })[1]
				if client == nil then
					vim.notify(("Invalid server name '%s'"):format(name))
				end
				return client
			end)
			:totable()
	end

	local detach_clients = {}
	for _, client in ipairs(clients) do
		detach_clients[vim.lsp.config[client.name]] = vim.lsp.get_buffers_by_client_id(client.id)
		client:stop(true)
	end

	local timer = assert(vim.uv.new_timer())
	timer:start(
		500,
		0,
		vim.schedule_wrap(function()
			for config, buffers in pairs(detach_clients) do
				for _, bufnr in ipairs(buffers) do
					require("k92.utils.lsp").start_config(config, bufnr)
					vim.notify("Restarted " .. config.name)
				end
			end
		end)
	)
end, {
	desc = "Manually restart the given language client(s)",
	nargs = "*",
	complete = complete_client,
})

vim.api.nvim_create_user_command("LspStart", function(info)
	local config = vim.lsp.config[info.args]
	local buffers_to_attach = {}

	if config == nil then
		vim.notify(("Invalid server name '%s'"):format(info.args))
		return
	end

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		if vim.tbl_contains(config.filetypes, filetype) then
			buffers_to_attach[#buffers_to_attach + 1] = bufnr
		end
	end

	for _, bufnr in ipairs(buffers_to_attach) do
		require("k92.utils.lsp").start_config(config, bufnr)
		vim.notify("Attached " .. config.name)
	end
end, {
	desc = "Manually launches a language server",
	nargs = "?",
	complete = complete_config,
})

vim.api.nvim_create_user_command("LspStop", function(info)
	---@type string
	local args = info.args

	local clients = {}

	-- default to stopping all servers on current buffer
	if #args == 0 then
		clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
	else
		clients = vim.iter(vim.split(args, " "))
			:map(function(name)
				local client = vim.lsp.get_clients({ name = name })[1]
				if client == nil then
					vim.notify(("Invalid server name '%s'"):format(name))
				end
				return client
			end)
			:totable()
	end

	for _, client in ipairs(clients) do
		client:stop(true)
		vim.notify("Stopped " .. client.name)
	end
end, {
	desc = "Manually stops the given language client(s)",
	nargs = "*",
	complete = complete_client,
})

vim.api.nvim_create_user_command("LspLog", function()
	local log_path = vim.lsp.get_log_path()
	local raw_lines = vim.fn.readfile(log_path)
	local message = {}
	local line_highlights = {}

	local icons = {
		START = " ",
		WARN = " ",
		ERROR = " ",
		INFO = " ",
	}

	local severity_highlights = {
		START = "DiagnosticHint",
		WARN = "DiagnosticWarn",
		ERROR = "DiagnosticError",
		INFO = "DiagnosticInfo",
	}

	if not raw_lines or #raw_lines == 0 then
		message = { "**LSP log file is empty or not found**" }
	else
		for _, line in ipairs(raw_lines) do
			-- Extract severity, timestamp, and the remaining log content.
			local severity, timestamp, rest = line:match("%[(.-)%]%[(.-)%]%s*(.+)")
			if severity and timestamp and rest then
				-- Trim any extra whitespace.
				rest = rest:match("^%s*(.-)%s*$")
				local filename, log_msg = rest:match("^(.-)%s*\t%s*(.+)$")

				-- If filename and log_msg weren't captured, fall back to full message.
				if not filename or not log_msg then
					filename = ""
					log_msg = rest
				else
					filename = filename:match("^%s*(.-)%s*$")
					log_msg = log_msg:match("^%s*(.-)%s*$")
				end

				local icon = icons[severity] or " "
				local line_idx = #message + 1
				local summary = string.format("- %s **%s** (%s):", icon, severity, timestamp)

				table.insert(message, summary)
				if filename and filename ~= "" then
					table.insert(message, string.format("    - **File:** `%s`", filename))
				end
				table.insert(message, string.format("    - **Message:** %s", log_msg))

				local start_col = summary:find(icon)
				if start_col then
					table.insert(line_highlights, {
						line = line_idx - 1,
						start_col = start_col - 1,
						end_col = start_col + #icon + #severity + 4,
						hl = severity_highlights[severity] or "Normal",
					})
				end
			else
				-- If the line doesn't match the expected pattern, include it as is.
				table.insert(message, line)
			end
		end
	end

	local buf_id
	info_buffer.open(buf_id, "lsplog", message, "markdown")
end, {
	desc = "Opens the Nvim LSP client log.",
})

vim.api.nvim_create_user_command("LspInfo", function()
	vim.cmd("checkhealth vim.lsp")
end, {
	desc = "Display detailed information about LSP clients",
})

vim.api.nvim_create_user_command("LspClearLog", function()
	local log_path = vim.lsp.get_log_path()
	vim.fn.writefile({}, log_path)
	vim.notify("Nvim LSP log file cleared.", vim.log.levels.INFO)
end, {
	desc = "Clears the Nvim LSP log file.",
})
