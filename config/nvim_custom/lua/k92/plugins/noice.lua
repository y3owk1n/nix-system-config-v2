return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		-- OPTIONAL:
		--   `nvim-notify` is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		"rcarriga/nvim-notify",
	},
	opts = function(_, opts)
		opts.routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
					},
				},
				view = "notify",
			},
		}

		table.insert(opts.routes, {
			filter = {
				event = "notify",
				find = "No information available",
			},
			opts = { skip = true },
		})
		local focused = true
		vim.api.nvim_create_autocmd("FocusGained", {
			callback = function()
				focused = true
			end,
		})
		vim.api.nvim_create_autocmd("FocusLost", {
			callback = function()
				focused = false
			end,
		})
		table.insert(opts.routes, 1, {
			filter = {
				cond = function()
					return not focused
				end,
			},
			view = "notify_send",
			opts = { stop = false },
		})

		opts.commands = {
			all = {
				-- options for the message history that you get with `:Noice`
				view = "split",
				opts = { enter = true, format = "details" },
				filter = {},
			},
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(event)
				vim.schedule(function()
					require("noice.text.markdown").keys(event.buf)
				end)
			end,
		})

		opts.lsp = {
			progress = {
				enabled = false,
			},
			-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
			},
		}

		opts.presets = {
			bottom_search = false, -- use a classic bottom cmdline for search
			command_palette = true, -- position the cmdline and popupmenu together
			long_message_to_split = true, -- long messages will be sent to a split
			-- inc_rename = false, -- enables an input dialog for inc-rename.nvim
			lsp_doc_border = true, -- add a border to hover docs and signature help
		}
	end,
}
