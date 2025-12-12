# Nix System Configuration

A declarative, reproducible system configuration using Nix, Nix Darwin, and Home Manager for macOS systems.

## 🚀 Quick Start

### Prerequisites

- macOS (tested on Apple Silicon)
- [Determinate Nix](https://determinate.systems/) installed

### Initial Setup

```bash
# Clone this repository
git clone https://github.com/y3owk1n/nix-system-config-v2.git
cd nix-system-config-v2

# Enter development environment
just dev

# Build and switch to your configuration
just rebuild personal-m3  # or work-imac
```

## 📁 Project Structure

```
├── darwin/           # macOS-specific configurations
│   ├── hosts/        # Host-specific system configs
│   ├── modules/      # Custom Darwin modules
│   └── shared/       # Shared Darwin configurations
├── home-manager/     # User environment configurations
│   ├── hosts/        # Host-specific user configs
│   ├── packages/     # Home Manager package definitions
│   └── shared/       # Shared user configurations
├── parts/            # Flake parts (system assembly)
├── config/           # Application configurations
└── scripts/          # Utility scripts
```

## 🛠️ Development

### Available Commands

```bash
just dev          # Enter development shell
just check        # Run all checks (lint, format, etc.)
just fmt          # Format code
just rebuild      # Rebuild system (requires host argument)
just update       # Update flake inputs
just gc           # Run garbage collection
```

### Development Environment

The devShell provides all necessary tools:

- `statix` & `deadnix` for Nix linting
- `treefmt` for code formatting
- `just` for command running
- `git` for version control

## 🏗️ Architecture

### Nix Flake Structure

- **Inputs**: External dependencies (nixpkgs, home-manager, darwin, etc.)
- **Outputs**:
  - `darwinConfigurations`: Complete system configurations
  - `homeManagerModules`: Reusable user configurations
  - `devShells`: Development environments
  - `checks`: CI validation
  - `formatter`: Code formatting

### Key Components

- **Nix Darwin**: macOS system management
- **Home Manager**: User environment management
- **Stylix**: Theming system
- **Treefmt**: Multi-language code formatting
- **Pre-commit hooks**: Automated code quality checks

## 🖥️ What I Use

### Core System

- **Nix**: [Determinate](https://determinate.systems) for reliable package management
- **Shell**: [fish](https://fishshell.com/) with custom functions
- **Terminal**: [ghostty](https://ghostty.org/) - fast, native terminal
- **Editor**: [neovim](https://neovim.io/) with custom lazy-loader
- **Multiplexer**: [tmux](https://github.com/tmux/tmux/wiki) for session management

### Development Tools

- **Version Control**: git with GPG signing
- **Prompt**: [starship](https://starship.rs/) for shell customization
- **Docker**: [orbstack](https://orbstack.dev/) for containerization
- **Network**: [tailscale](https://tailscale.com/) for mesh networking

### macOS Integration

- **Automation**: [Hammerspoon](https://www.hammerspoon.org/) with custom spoons
- **Keyboard**: [kanata](https://github.com/jtroo/kanata) for key remapping
- **Launcher**: Spotlight with custom shortcuts
- **Window Management**: Built-in with [Bindery.spoon](https://github.com/y3owk1n/Bindery.spoon)

### Browser & Extensions

- **Browser**: Safari with custom keyboard shortcuts
- **Extensions**:
  - [wBlock](https://github.com/0xCUB3/wBlock) - content blocker
  - [Refined GitHub](https://github.com/refined-github/refined-github) - enhanced GitHub UX

## 🔧 Customization

### Adding a New Host

1. Create `parts/hosts/new-host.nix` based on existing hosts
2. Update hostname, username, and user details
3. Add any host-specific configurations
4. Run `just rebuild new-host`

### Adding Home Manager Packages

1. Create `home-manager/packages/new-package.nix`
2. Add to appropriate host configuration in `home-manager/hosts/`
3. Test with `just check`

### Custom Modules

- **Darwin modules**: Add to `darwin/modules/`
- **Home Manager modules**: Add to `home-manager/custom/`
- **Shared configurations**: Use `shared/` directories

## 📋 Maintenance

### Regular Tasks

```bash
# Update dependencies
just update

# Clean up old generations
just gc

# Check configuration
just check
```

### Troubleshooting

See [NOTES.md](NOTES.md) for detailed troubleshooting guides covering:

- SSL certificate issues
- DNS configuration
- GPG key management
- Service management
- Common Nix problems

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper formatting (`just fmt`)
4. Test with `just check`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.
