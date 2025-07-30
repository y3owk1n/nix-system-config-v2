local M = {}

local mod_root = "lsp"
local mod_path = vim.fn.stdpath("config") .. "/lua/" .. mod_root

---@return string[]
function M.discover()
  ---@type string[]
  local modules = {}

  for _, file in
    ipairs(vim.fs.find(function(name)
      return name:sub(-4) == ".lua"
    end, { type = "file", limit = math.huge, path = mod_path }))
  do
    local rel = file:sub(#mod_path + 2, -5):gsub("/", ".") -- remove path prefix & .lua
    if rel ~= "init" then
      local module = mod_root .. "." .. rel
      table.insert(modules, module)
    end
  end

  return modules
end

---@param modules string[]
function M.setup_modules(modules)
  for _, module in ipairs(modules) do
    require(module)
  end
end

function M.setup_autocmds()
  local augroup = vim.api.nvim_create_augroup("LspProgress", { clear = true })

  ---@type table<number, {token:lsp.ProgressToken, msg:string, done:boolean}[]>
  local progress = vim.defaulttable()
  vim.api.nvim_create_autocmd("LspProgress", {
    group = augroup,
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
end

function M.init()
  local modules = M.discover()
  M.setup_modules(modules)

  M.setup_autocmds()
end

return M
