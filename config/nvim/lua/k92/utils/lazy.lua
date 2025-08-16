local M = {}

---@param plugin_name string
function M.plugin_is_loaded(plugin_name)
  return vim.tbl_get(require("lazy.core.config"), "plugins", plugin_name, "_", "loaded")
end

---@param plugin_name string
---@return boolean
function M.plugin_load(plugin_name)
  if not M.plugin_is_loaded(plugin_name) then
    require("lazy").load({ plugins = { plugin_name } })
  end
  return true
end

---@param clients string[]
---@param plugin_name string
function M.lazy_load_lsp_attach(clients, plugin_name)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_" .. plugin_name .. "_attach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)

      local allowed_clients = clients

      if not client or not vim.tbl_contains(allowed_clients, client.name) then
        return
      end

      M.plugin_load(plugin_name)
    end,
  })
end

return M
