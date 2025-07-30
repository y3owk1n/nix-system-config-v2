local util = require("lspconfig.util")
local utils_lsp = require("utils.lsp")

--- Find Tailwind entry CSS file within a root directory
---@param root_dir string
---@return string|nil
local function find_tailwind_entry_file(root_dir)
  local uv = vim.loop

  local candidates = {
    "tailwind.css",
    "globals.css",
    "app.css",
    "src/styles.css",
    "src/index.css",
    "styles/globals.css",
    "packages/ui/src/globals.css",
    "packages/ui/src/styles/globals.css",
    "packages/ui/src/styles.css",
  }

  for _, relpath in ipairs(candidates) do
    local fullpath = root_dir .. "/" .. relpath
    local stat = uv.fs_stat(fullpath)
    if stat and stat.type == "file" then
      local fd = uv.fs_open(fullpath, "r", 438) -- 0666
      if fd then
        local content = uv.fs_read(fd, stat.size, 0)
        uv.fs_close(fd)

        if content and (content:find('@import%s+"tailwindcss"', 1, true) or content:find("@tailwind", 1, true)) then
          return fullpath
        end
      end
    end
  end

  return nil
end

vim.lsp.config("tailwindcss", {
  before_init = function(_, config)
    if not config.settings then
      config.settings = {}
    end
    if not config.settings.editor then
      config.settings.editor = {}
    end
    if not config.settings.editor.tabSize then
      -- set tab size for hover
      config.settings.editor.tabSize = vim.lsp.util.get_effective_tabstop()
    end

    local root_dir = config.root_dir
    if root_dir then
      local entry_file = find_tailwind_entry_file(root_dir)
      if entry_file then
        config.settings.tailwindCSS = config.settings.tailwindCSS or {}
        config.settings.tailwindCSS.experimental = config.settings.tailwindCSS.experimental or {}
        config.settings.tailwindCSS.experimental.configFile = entry_file
      end
    end
  end,
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)

    local workspace_root = util.root_pattern("pnpm-workspace.yaml")(fname)

    local package_root = util.root_pattern("package.json")(fname)

    if package_root then
      local package_data = utils_lsp.decode_json_file(package_root .. "/package.json")
      if
        package_data
        and (
          utils_lsp.has_nested_key(package_data, "dependencies", "tailwindcss")
          or utils_lsp.has_nested_key(package_data, "devDependencies", "tailwindcss")
        )
      then
        if workspace_root then
          on_dir(workspace_root)
        else
          on_dir(package_root)
        end
      end
    end
  end,
})

vim.lsp.enable("tailwindcss")
