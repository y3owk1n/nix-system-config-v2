---@type LazySpec
return {
  "echasnovski/mini.starter",
  event = "VimEnter",
  opts = function()
    local starter = require("mini.starter")
    local warp_exists, warp_list = pcall(require, "warp.list")

    local new_section = function(name, action, section)
      return { name = name, action = action, section = section }
    end

    local items = {
      new_section("e: Explore", "lua require('mini.files').open(vim.uv.cwd(), true)", "Navigate"),
      new_section("f: Find File", "Pick files", "Navigate"),
      new_section("g: Grep Text", "Pick grep_live", "Navigate"),
    }

    if warp_exists then
      local warps = warp_list.get.all()

      if #warps > 0 then
        for index, warp in ipairs(warps) do
          local display = vim.fn.pathshorten(vim.fn.fnamemodify(warp.path, ":~:."))

          table.insert(items, new_section(index .. ": " .. display, "WarpGoToIndex " .. index, "Warp"))
        end
      end
    end

    if package.loaded.lazy then
      table.insert(items, new_section("l: Lazy", "Lazy", "Tools"))
    end

    table.insert(items, new_section("q: Quit", "qa", "Built-in"))

    local function header_cb()
      local versioninfo = vim.version() or {}
      local major = versioninfo.major or ""
      local minor = versioninfo.minor or ""
      local patch = versioninfo.patch or ""
      local prerelease = versioninfo.prerelease or ""
      local build = versioninfo.build or ""

      local version = string.format("NVIM v%s.%s.%s", major, minor, patch)
      if prerelease ~= "" then
        version = version .. string.format(" (%s-%s)", prerelease, build)
      end
      return version
    end

    local opts = {
      header = header_cb,
      evaluate_single = true,
      items = items,
      content_hooks = {
        starter.gen_hook.adding_bullet("░ ", false),
        starter.gen_hook.aligning("center", "center"),
      },
      footer = "",
      silent = true,
    }

    return opts
  end,
  config = function(_, config)
    local plugin = require("mini.starter")
    plugin.setup(config)

    -- close Lazy and re-open when starter is ready
    if vim.o.filetype == "lazy" then
      vim.cmd.close()
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniStarterOpened",
        callback = function()
          require("lazy").show()
        end,
      })
    end

    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyVimStarted",
      callback = function(ev)
        local stats = require("lazy").stats()
        local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
        plugin.config.footer = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
        -- INFO: based on @echasnovski's recommendation (thanks a lot!!!)
        if vim.bo[ev.buf].filetype == "ministarter" then
          pcall(plugin.refresh)
        end
      end,
    })
  end,
}
