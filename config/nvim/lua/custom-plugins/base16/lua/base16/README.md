# Base16.nvim

A highly configurable and feature-rich Base16 colorscheme engine for Neovim that goes beyond traditional base16
colorscheme plugins.

## Features

- **Semantic Color System**: Use intuitive color names like `red`, `blue`, `bg`, `fg` instead of cryptic base16 codes
- **Advanced Styling**: Support for italics, bold text, transparency, and window dimming
- **Overrideable Highlights**: Override any highlight group with custom colors and styles
- **Smart Blending**: Sophisticated color blending with configurable opacity levels
- **Extensive Plugin Support**: Built-in integrations for popular plugins (Mini.nvim, Blink, RenderMarkdown, Which-Key, etc.)
- **Treesitter Ready**: Full Treesitter and LSP semantic token support
- **Customizable Highlights**: Override any highlight group with custom colors and styles
- **Validation System**: Comprehensive configuration validation with helpful error messages
- **Performance Optimized**: Efficient caching and minimal runtime overhead

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "y3owk1n/base16.nvim",
  priority = 1000, -- Ensure it loads first
  config = function()
    require("base16").setup({
      colors = {
        base00 = "#1f1f28", -- Default background
        base01 = "#2a2a37", -- Lighter background
        base02 = "#3a3a4e", -- Selection background
        base03 = "#4e4e5e", -- Comments, invisibles
        base04 = "#9e9eaf", -- Dark foreground
        base05 = "#c5c5da", -- Default foreground
        base06 = "#dfdfef", -- Light foreground
        base07 = "#e6e6f0", -- Lightest foreground
        base08 = "#ff5f87", -- Red: Variables, tags, deleted
        base09 = "#ff8700", -- Orange: Integers, booleans
        base0A = "#ffaf00", -- Yellow: Classes, search
        base0B = "#5fff87", -- Green: Strings, inserted
        base0C = "#5fd7ff", -- Cyan: Support, regex
        base0D = "#5fafff", -- Blue: Functions, headings
        base0E = "#af87ff", -- Purple: Keywords, changed
        base0F = "#d7875f", -- Brown: Deprecated
      },
    })
    vim.cmd.colorscheme("base16")
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "y3owk1n/base16.nvim",
  config = function()
    require("base16").setup({
      -- Your configuration here
    })
    vim.cmd.colorscheme("base16")
  end
}
```

## Quick Start

```lua
-- Minimal setup with a predefined color palette
require("base16").setup({
  colors = {
    -- Kanagawa-inspired colors
    base00 = "#1f1f28", base01 = "#2a2a37", base02 = "#3a3a4e", base03 = "#4e4e5e",
    base04 = "#9e9eaf", base05 = "#c5c5da", base06 = "#dfdfef", base07 = "#e6e6f0",
    base08 = "#ff5f87", base09 = "#ff8700", base0A = "#ffaf00", base0B = "#5fff87",
    base0C = "#5fd7ff", base0D = "#5fafff", base0E = "#af87ff", base0F = "#d7875f",
  },
})
vim.cmd.colorscheme("base16")
```

## Configuration

Note that everything is **opt-in** by default. You need to enable them in the config.

### Complete Configuration Example

```lua
require("base16").setup({
  colors = {
    -- Base16 color palette (required)
    base00 = "#1f1f28", base01 = "#2a2a37", base02 = "#3a3a4e", base03 = "#4e4e5e",
    base04 = "#9e9eaf", base05 = "#c5c5da", base06 = "#dfdfef", base07 = "#e6e6f0",
    base08 = "#ff5f87", base09 = "#ff8700", base0A = "#ffaf00", base0B = "#5fff87",
    base0C = "#5fd7ff", base0D = "#5fafff", base0E = "#af87ff", base0F = "#d7875f",
  },

  styles = {
    italic = true,               -- Enable italic text
    bold = true,                 -- Enable bold text
    transparency = false,        -- Transparent background
    dim_inactive_windows = true, -- Dim inactive windows
    blends = {
      subtle = 10,               -- Barely visible (10%)
      medium = 15,               -- Noticeable (15%)
      strong = 25,               -- Prominent (25%)
      super = 50,                -- Very prominent (50%)
    },
  },

  plugins = {
    enable_all = false,          -- Disable all plugins
    nvim_mini_mini_icons = true, -- Enable Mini Icons
    nvim_mini_mini_diff = true,  -- Enable Mini Diff
    saghen_blink_cmp = true,     -- Enable Blink
    folke_which_key_nvim = true, -- Enable Which-Key
  },

  -- Override semantic color groups
  color_groups = {
    syntax = {
      keyword = "purple",        -- Use purple for keywords
      string = function(c)       -- Dynamic color calculation
        return c.green
      end,
    },
    states = {
      error = "red",
      warning = "orange",
      info = "blue",
    },
  },

  -- Custom highlight groups
  highlight_groups = {
    -- Make comments more subtle
    Comment = { fg = "fg_dim", italic = true },

    -- Custom highlight for your plugin
    MyPluginHighlight = {
      fg = "blue",
      bg = "bg_light",
      bold = true
    },
  },

  -- Hook to modify highlights before they're applied
  before_highlight = function(group, opts, colors)
    if group == "Normal" and opts.bg then
      -- Make background slightly darker
      opts.bg = require("base16").blend_colors(opts.bg, "#000000", 0.1)
    end
  end,
})
```

### Default Configuration

```lua
{
  colors = {},
  highlight_groups = {},
  before_highlight = nil,
  styles = {
    italic = false,
    bold = false,
    transparency = false,
    dim_inactive_windows = false,
    blends = {
      subtle = 10,
      medium = 15,
      strong = 25,
      super = 50,
    },
  },
  plugins = {
    enable_all = false,
  },
  color_groups = {
    -- Background variations
    backgrounds = {
      normal = "bg",
      dim = "bg_dim",
      light = "bg_light",
      selection = "bg_light",
      cursor_line = function(c)
        return U.blend(c.bg_light, c.bg, 0.6)
      end,
      cursor_column = function(c)
        return U.blend(c.bg_dim, c.bg, 0.3)
      end,
    },

    -- Foreground variations
    foregrounds = {
      normal = "fg",
      dim = "fg_dim",
      dark = "fg_dark",
      light = "fg_light",
      bright = "fg_bright",
      comment = "fg_dark",
      line_number = function(c)
        return U.blend(c.fg_dim, c.bg, 0.7)
      end,
    },

    -- Semantic colors for syntax
    syntax = {
      variable = "fg",
      constant = "orange",
      string = "green",
      number = "orange",
      boolean = "orange",
      keyword = "purple",
      function_name = "blue",
      type = "yellow",
      comment = "fg_dark",
      operator = "cyan",
      delimiter = "brown",
    },

    -- UI state colors
    states = {
      error = "red",
      warning = "yellow",
      info = "blue",
      hint = "cyan",
      success = "green",
    },

    -- Diff colors
    diff = {
      added = "green",
      removed = "red",
      changed = "orange",
      text = "blue",
    },

    -- Search and selection
    search = {
      match = "yellow",
      current = "orange",
      incremental = "orange",
    },
  },
}
```

### Color System

Base16.nvim apply highlights based on [base16 convention](https://github.com/tinted-theming/home/blob/main/styling.md), and provides two ways to reference colors:

#### Raw Base16 Colors

```lua
-- Backgrounds
base00, base01, base02,

-- Foregrounds
base03, base04, base05, base06, base07,

-- Colors
base08, base09, base0A, base0B, base0C, base0D, base0E, base0F
```

#### Semantic Aliases (Recommended)

```lua
-- Backgrounds
bg, bg_dim, bg_light

-- Foregrounds
fg, fg_dim, fg_dark, fg_light, fg_bright

-- Colors
red, orange, yellow, green, cyan, blue, purple, brown
```

### Style Options

```lua
styles = {
  italic = true,                    -- Enable italics for keywords, comments
  bold = true,                      -- Enable bold for headings, keywords
  transparency = false,             -- Transparent background
  dim_inactive_windows = true,      -- Dim non-focused windows
  blends = {
    subtle = 10,    -- 10% opacity for subtle backgrounds
    medium = 15,    -- 15% opacity for noticeable highlights
    strong = 25,    -- 25% opacity for prominent features
    super = 50,     -- 50% opacity for very prominent features
  },
}
```

### Plugin Integrations

Base16.nvim includes built-in support for these popular plugins:

- **Mini.nvim** (icons, diff, files, pick)
- **Blink Cmp** - Modern completion engine
- **RenderMarkdown** - Enhanced markdown rendering
- **Which-Key** - Keybinding helper
- **Undo Glow** - Undo/redo visualization
- **Grug Far** - Search and replace
- **Flash** - Jump navigation

Enable specific plugins:

```lua
plugins = {
  saghen_blink_cmp = true,
  folke_which_key_nvim = true,
  -- Or enable all supported plugins
  enable_all = true,
}
```

#### Why plugin X is not supported?

It's simply because I am not using them myself or I had been lazy. TLDR, I am happy to accept PRs for more plugin integrations.

## API Reference

### Core Functions

```lua
local base16 = require("base16")

-- Setup the plugin
base16.setup(config)

-- Apply the colorscheme
vim.cmd.colorscheme("base16")

-- Get semantic color palette
local colors = base16.colors()
-- Returns: { bg = "#1f1f28", red = "#ff5f87", ... }

-- Get specific colors
local red = base16.get_color("red")
local bg = base16.get_color("bg")

-- Get multiple colors
local my_colors = base16.get_colors({"red", "blue", "bg"})

-- Get raw base16 colors only
local raw = base16.raw_colors()

-- Blend colors
local blended = base16.blend_colors("#ff0000", "#000000", 0.5)
```

### Advanced Usage

```lua
-- Get colors from semantic groups
local error_color = base16.get_group_color("states", "error")
local keyword_color = base16.get_group_color("syntax", "keyword")

-- Validate color configuration
local valid, missing = base16.validate_colors(my_colors)
if not valid then
  print("Missing colors:", table.concat(missing, ", "))
end
```

## Customization Examples

### Custom Color Scheme

```lua
-- Tokyo Night inspired colors
require("base16").setup({
  colors = {
    base00 = "#1a1b26", base01 = "#16161e", base02 = "#2f3549", base03 = "#444b6a",
    base04 = "#787c99", base05 = "#a9b1d6", base06 = "#cbccd1", base07 = "#d5d6db",
    base08 = "#c0caf5", base09 = "#a9b1d6", base0A = "#0db9d7", base0B = "#9ece6a",
    base0C = "#b4f9f8", base0D = "#2ac3de", base0E = "#bb9af7", base0F = "#f7768e",
  },
})
```

### Transparent Background

```lua
require("base16").setup({
  colors = { --[[ your colors ]] },
  styles = {
    transparency = true,
  },
})
```

### Custom Syntax Colors

```lua
require("base16").setup({
  colors = { --[[ your colors ]] },
  color_groups = {
    syntax = {
      keyword = "purple",
      function_name = "blue",
      string = "green",
      comment = function(c)
        -- Make comments blend with background
        return require("base16").blend_colors(c.fg_dim, c.bg, 0.6)
      end,
    },
  },
})
```

## Troubleshooting

### Colors Not Applying

Make sure you call `vim.cmd.colorscheme("base16")` after setup:

```lua
require("base16").setup({ --[[ config ]] })
vim.cmd.colorscheme("base16") -- This line is required
```

### Plugin Integration Issues

Check if plugins are enabled in your configuration:

```lua
plugins = {
  saghen_blink_cmp = true, -- Enable Blink integration
}
```

### Configuration Validation

Base16.nvim provides detailed error messages for invalid configurations. Check `:messages` if setup fails.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### Adding Plugin Support

To add support for a new plugin:

1. Add the plugin option to the `Base16.Config.Plugins` type
2. Add highlight setup in `setup_integration_hl()`
3. Use the `U.has_plugin()` utility to check if enabled

## License

MIT License - see LICENSE file for details.
