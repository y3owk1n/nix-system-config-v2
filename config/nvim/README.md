# Neovim Configuration Mirror

This repository serves as a mirror of the Neovim configuration from my [Nix System Configuration](https://github.com/y3owk1n/nix-system-config-v2). It allows me to maintain a consistent Neovim setup across different environments, especially on devices where Nix isn't available.

## Purpose

The primary goal of this mirror is to provide a portable and up-to-date Neovim configuration that can be easily deployed on various systems. This setup ensures that I can work seamlessly across different devices without the need for Nix, while still benefiting from my personalized Neovim environment.

## Features

- **Consistency:** Maintain the same Neovim setup across multiple devices.
- **Portability:** Easily deploy the configuration on systems without Nix.
- **Up-to-date:** Automatically synchronized with the latest changes from the original configuration.

## Installation

This config is very personalised to my own need. But if you really want to try it out, do as follows:

```bash
git clone https://github.com/y3owk1n/nvim.git ~/.config/nvim

# or if you already have existing config
git clone https://github.com/y3owk1n/nvim.git ~/.config/nvim-k92
```

Ensure that you have Neovim installed. If you don't, feel free to try out [my neovim version switcher cli](https://github.com/y3owk1n/nvs) that helps manages different Neovim verion and configuration for you.

## Synchronization

This repository is synchronized with the Neovim configuration from my Nix System Configuration. The synchronization process involves:

- **Subtree Merging**: Using Git's subtree merge strategy to incorporate changes from the main repository.
- **Automatic Updates**: Committing and pushing updates automatically when new commits added to keep this mirror current.

## Contributions

As this repository is a personal mirror of my Neovim configuration, contributions are not expected.
