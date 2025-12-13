# My Personal Nix System Configuration

This is a project to help me to manage my Nix system configuration, mainly with Darwin and Home Manager.

## Project Structure

```
├── config/           # Application configurations (Neovim, Kanata, etc.)
├── darwin/           # macOS (Darwin) specific configurations
├── home-manager/     # Cross-platform user environment
├── parts/            # Reusable flake parts and modules
├── scripts/          # Utility scripts for system management
├── .github/          # CI/CD workflows
├── Justfile          # Task runner for common operations
└── flake.nix         # Main Nix flake definition
```

## What do I use?

### General

- Nix: [Determinate](https://determinate.systems)
- Shell: [fish](https://fishshell.com/)
- Terminal: [ghostty](https://ghostty.org/)
- Editor: [neovim](https://neovim.io/) with custom lazy-loader plus vim.pack
- Neovim Version Manager: [nvs](https://github.com/y3owk1n/nvs)
- Multiplexer: [tmux](https://github.com/tmux/tmux/wiki)
- Prompt: [starship](https://starship.rs/)
- Browser: Safari
- Docker: [orbstack](https://orbstack.dev/)
- Network: [tailscale](https://tailscale.com/)
- Launcher: Spotlight
- Tiling Window Manager: [rift](https://github.com/acsandmann/rift)
- Systemwide vimium: [neru](https://github.com/y3owk1n/neru)
- Version Control: git
- Keyboard Remapping: [kanata](https://github.com/jtroo/kanata) - only used to remap on mac default keyboard

## Getting Started

### Initial Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/y3owk1n/nix-system-config-v2.git
   cd nix-system-config-v2
   ```

2. **Initial installation:**

   ```bash
   # For macOS
   just init <hostname>

   # Or manually
   nix run nix-darwin -- switch --flake .#<hostname>
   ```

3. **Update the system:**

   ```bash
   just rebuild <hostname>
   ```

### Common Tasks

- **Format code:** `just fmt`
- **Run checks:** `just check`
- **Enter dev shell:** `just dev`
- **Clean up:** `just clean`

See `Justfile` for all available commands.

## Scripts

The `scripts/` directory contains various utilities:

- `init.sh` - Initial Nix Darwin setup
- `run-project-cmd.sh` - Interactive project command runner
- `passx.sh` - Password store environment manager
- `nvim-reset.sh` - Neovim configuration reset
- `atuin-run-script.sh` - Atuin shell history integration

## Safari Extensions

- [wBlock](https://github.com/0xCUB3/wBlock) - content blocker for Safari (ublock alternative)
- [Refined Github](https://github.com/refined-github/refined-github) - better github experience

## Configuration Philosophy

This configuration follows these principles:

- **Modular:** Each tool/service has its own module for easy maintenance
- **Cross-platform:** Works on both macOS and Linux where possible
- **Secure:** Uses GPG for secrets, secure defaults for services
- **Minimal:** Only includes what's needed, avoids bloat
- **Documented:** Extensive comments and documentation for maintainability
- **Automated:** CI/CD for validation, scripts for common tasks

## Contributing

1. Make changes to the appropriate module
2. Run `just fmt` to format code
3. Run `just check` to validate
4. Test on target system with `just rebuild <hostname>`
5. Commit with descriptive message
