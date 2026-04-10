-- =========================================================
--  Just overrides
-- =========================================================

vim.lsp.config("just", {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
})

-- =========================================================
--  Lua overrides (so that vim don't shout at me)
-- =========================================================

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      completion = { enable = true },
      diagnostics = {
        enable = true,
        globals = { "vim" },
      },
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

-- =========================================================
--  Tailwind overrides (default doesn't work with monorepo with v4)
-- =========================================================

vim.lsp.config("tailwindcss", {
  before_init = function(_, config)
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
    local util = require("lspconfig.util")

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

    local fname = vim.api.nvim_buf_get_name(bufnr)

    local workspace_root = util.root_pattern("pnpm-workspace.yaml")(fname)

    local package_root = util.root_pattern("package.json")(fname)

    if package_root then
      local package_data = decode_json_file(package_root .. "/package.json")
      if
        package_data
        and (
          has_nested_key(package_data, "dependencies", "tailwindcss")
          or has_nested_key(package_data, "devDependencies", "tailwindcss")
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

-- =========================================================
--  Enable LSPs
-- =========================================================

vim.lsp.enable({
  "bashls",
  "biome",
  "clangd",
  "docker_language_server",
  "docker_compose_language_service",
  "eslint",
  "gh_actions_ls",
  "gopls",
  "jsonls",
  "just",
  "lua_ls",
  "marksman",
  "nixd",
  "prismals",
  "rust_analyzer",
  "tailwindcss",
  "vtsls",
  "yamlls",
})
