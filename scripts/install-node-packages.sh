#!/bin/bash

# Save the current directory
original_dir=$(pwd)

# Set the target directory
target_dir=~/nix-system-config-v2/home/node-packages

# Change to the target directory
cd "$target_dir" || {
    echo "Error: Could not change to directory $target_dir"
    exit 1
}

# Run the command with error handling
# nix-shell -p nodePackages.node2nix --command "node2nix -18 -i ./node-packages.json -o node"
nix-shell -p nodePackages.node2nix --command "node2nix nodejs-22_x -i ./node-packages.json -o node"

# Check the exit status of the last command
if [ $? -ne 0 ]; then
    echo "Error: Failed to run the command"
    cd "$original_dir" # Return to the original directory even in case of an error
    exit 1
fi

echo "Command executed successfully"

# Return to the original directory
cd "$original_dir"
exit 0
