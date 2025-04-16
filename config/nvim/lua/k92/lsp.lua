local augroup = require("k92.utils.autocmds").augroup

vim.lsp.config("*", { capabilities = vim.lsp.protocol.make_client_capabilities() })

vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	virtual_lines = {
		current_line = true,
	},
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

		map(event.buf, "<leader>ca", vim.lsp.buf.code_action, "Code Actions")

		map(event.buf, "gK", vim.lsp.buf.signature_help, "Signature help")

		map(event.buf, "<leader>ls", ":LspStop<cr>", "Stop all LSP")
		map(event.buf, "<leader>lr", ":LspRestart<cr>", "Restart all LSP")
		map(event.buf, "<leader>lS", ":LspStart<cr>", "Start all LSP")
		map(event.buf, "<leader>ll", ":LspLog<cr>", "Log")
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

vim.api.nvim_create_user_command("LspRestart", function()
	local function restart_clients(clients)
		vim.notify("Restarting all LSP clients...")
		vim.lsp.stop_client(clients, true)
		vim.defer_fn(function()
			vim.cmd("edit")
			vim.notify("Restarting LSP clients complete...")
		end, 1000)
	end

	local clients = vim.lsp.get_clients()
	restart_clients(clients)
end, {
	desc = "Restart LSP clients.",
})

vim.api.nvim_create_user_command("LspStart", function()
	vim.notify("Starting all LSP clients...")
	vim.defer_fn(function()
		vim.cmd("edit")
		vim.notify("Restarting LSP clients complete...")
	end, 1000)
end, {
	desc = "Start LSP clients.",
})

vim.api.nvim_create_user_command("LspStop", function()
	local clients = vim.lsp.get_clients()
	vim.notify("Stopping all LSP clients...")
	vim.lsp.stop_client(clients, true)
	vim.notify("Restarting LSP clients complete...")
end, {
	desc = "Stop Lsp clients.",
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

	local ns = vim.api.nvim_create_namespace("lsp_log")

	Snacks.win({
		title = "LSP Log",
		title_pos = "center",
		text = message,
		scratch_ft = "float_info",
		ft = "markdown",
		fixbuf = true,
		width = 0.8,
		height = 0.8,
		position = "float",
		border = "rounded",
		minimal = true,
		wo = {
			spell = false,
			wrap = false,
			signcolumn = "yes",
			statuscolumn = " ",
			conceallevel = 3,
			concealcursor = "nvic",
		},
		bo = {
			readonly = true,
			modifiable = false,
		},
		keys = {
			q = "close",
		},
		on_buf = function(self)
			for _, hl in ipairs(line_highlights) do
				vim.api.nvim_buf_set_extmark(self.buf, ns, hl.line, hl.start_col, {
					end_col = hl.end_col,
					hl_group = hl.hl,
				})
			end
		end,
	})
end, {
	desc = "Opens the Nvim LSP client log.",
})

vim.api.nvim_create_user_command("LspInfo", function()
	local clients = vim.lsp.get_clients({
		bufnr = 0,
	})
	local message = {}

	if #clients == 0 then
		table.insert(message, " **No active LSP clients**")
	else
		table.insert(message, "**Active LSP Clients: " .. #clients .. "**")
		table.insert(message, "")
		table.insert(message, "---")
		table.insert(message, "")

		for i, client in ipairs(clients) do
			local buffers = vim.lsp.get_buffers_by_client_id(client.id)

			-- Client header
			table.insert(message, i .. ". `" .. client.name .. "` (ID: " .. client.id .. ")")
			table.insert(message, "")

			-- Root directory
			table.insert(message, " **Root Directory:** `" .. (client.config.root_dir or "Not available") .. "`")

			-- Executable command
			local cmd_path = client.config.cmd and client.config.cmd[1] or "N/A"
			table.insert(message, " **Command:** `" .. cmd_path .. "`")

			-- Initialization status
			table.insert(
				message,
				" **Status:** `" .. (client.initialized and "Initialized" or "Not initialized") .. "`"
			)

			-- Formatting support
			local caps = client.server_capabilities

			if caps then
				local has_formatting = caps.documentFormattingProvider or caps.documentRangeFormattingProvider
				table.insert(message, " **Formatting:** " .. (has_formatting and "Supported" or "Not supported"))

				-- Feature summary
				local summary = {}
				if caps.definitionProvider then
					table.insert(summary, "Definition")
				end
				if caps.referencesProvider then
					table.insert(summary, "References")
				end
				if caps.hoverProvider then
					table.insert(summary, "Hover")
				end
				if caps.renameProvider then
					table.insert(summary, "Rename")
				end
				if caps.completionProvider then
					table.insert(summary, "Completion")
				end
				if caps.codeActionProvider then
					table.insert(summary, "CodeAction")
				end
				if caps.signatureHelpProvider then
					table.insert(summary, "SignatureHelp")
				end
				table.insert(
					message,
					" **Supported Features:** " .. (#summary > 0 and table.concat(summary, ", ") or "None")
				)
			end

			-- Initialization options
			if client.config.init_options then
				table.insert(message, " **Initialization Options:**")
				table.insert(message, "```lua")
				for line in vim.inspect(client.config.init_options):gmatch("[^\r\n]+") do
					table.insert(message, line)
				end
				table.insert(message, "```")
			end

			-- Workspace folders
			if client.workspace_folders then
				table.insert(message, " **Workspace Folders:**")
				for _, folder in ipairs(client.workspace_folders) do
					table.insert(message, "    - `" .. folder.name .. "` → `" .. folder.uri .. "`")
				end
			end

			-- Attached buffers
			table.insert(message, " **Attached Buffers:**")
			if #buffers > 0 then
				for _, bufnr in ipairs(buffers) do
					if vim.api.nvim_buf_is_valid(bufnr) then
						local name = vim.api.nvim_buf_get_name(bufnr)
						table.insert(message, "    - `" .. bufnr .. "`: " .. (name ~= "" and name or "*[No Name]*"))
					end
				end
			else
				table.insert(message, "     None")
			end

			-- Diagnostics
			local has_diagnostics = false
			for _, bufnr in ipairs(buffers) do
				if vim.api.nvim_buf_is_valid(bufnr) then
					local diagnostics = vim.diagnostic.get(bufnr)
					if #diagnostics > 0 then
						has_diagnostics = true
						break
					end
				end
			end
			table.insert(message, " **Diagnostics:** " .. (has_diagnostics and "Available" or "None"))

			-- Capabilities (verbose, last)
			table.insert(message, " **Full Capabilities:**")
			table.insert(message, "```lua")
			for line in vim.inspect(caps):gmatch("[^\r\n]+") do
				table.insert(message, line)
			end
			table.insert(message, "```")

			table.insert(message, "")
		end
	end

	table.insert(message, "---")
	table.insert(message, "_Press `q` to close this window_")

	Snacks.win({
		title = "LSP Information",
		title_pos = "center",
		text = message,
		scratch_ft = "float_info",
		ft = "markdown",
		fixbuf = true,
		width = 0.8,
		height = 0.8,
		position = "float",
		border = "rounded",
		minimal = true,
		wo = {
			spell = false,
			wrap = false,
			signcolumn = "yes",
			statuscolumn = " ",
			conceallevel = 3,
			concealcursor = "nvic",
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
	desc = "Display detailed information about LSP clients",
})

vim.api.nvim_create_user_command("LspClearLog", function()
	local log_path = vim.lsp.get_log_path()
	vim.fn.writefile({}, log_path)
	vim.notify("Nvim LSP log file cleared.", vim.log.levels.INFO)
end, {
	desc = "Clears the Nvim LSP log file.",
})
