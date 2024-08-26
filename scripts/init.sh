#!/bin/bash

# Find the directory containing 'nix-system-config-v2' (or similar) in its name
echo "Finding *nix-system-config* directory..."
config_dir=$(find ~ -maxdepth 1 -type d -name "*nix-system-config*" -print -quit)

if [ -z "$config_dir" ]; then
    echo "Error: Could not find a directory matching *nix-system-config*"
    exit 1
fi

echo "Found *nix-system-config* directory at $config_dir"

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a user argument"
    echo "Usage: $0 <user>"
    exit 1
fi

user="$1"

echo "Build nix for user: $user"

# Run the install-node-packages script
echo "Running install-node-packages script..."
bash "$config_dir/scripts/install-node-packages.sh"

# Check the exit status of the last command
if [ $? -ne 0 ]; then
    echo "Error: Failed to run the install-node-packages script"
    exit 1
fi

echo "install-node-packages script executed successfully"

# Run the nix command with the found directory and provided user
echo "Building nix-darwin now..."
nix run nix-darwin -- switch --flake "$config_dir#$user"

echo "Initialisation completed"
