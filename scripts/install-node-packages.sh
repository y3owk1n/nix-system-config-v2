#!/bin/bash

config_dir=$(find ~ -maxdepth 1 -type d -name "*nix-system-config*" -print -quit)

if [ -z "$config_dir" ]; then
    echo "Error: Could not find a directory matching *nix-system-config*"
    exit 1
fi

# Save the current directory
original_dir=$(pwd)

# Set the target directory
target_dir="$config_dir/home/node-packages"

# Change to the target directory
cd "$target_dir" || {
    echo "Error: Could not change to directory $target_dir"
    exit 1
}

# Check if node-packages.json exists
if [ ! -f node-packages.json ]; then
    echo "node-packages.json does not exist. Skipping node2nix command."
    cd "$original_dir"
    exit 0
fi

# Check if node-packages.json is a valid JSON array and not empty
if ! jq -e '. | arrays and length > 0' node-packages.json >/dev/null 2>&1; then
    echo "node-packages.json is not a valid non-empty JSON array. Skipping node2nix command."
    cd "$original_dir"
    exit 0
fi

# Run the command with error handling
# nix-shell -p nodePackages.node2nix --command "node2nix -18 -i ./node-packages.json -o node"
nix-shell -p nodePackages.node2nix --command "node2nix -18 -i ./node-packages.json -o node"

# Check the exit status of the last command
if [ $? -ne 0 ]; then
    echo "Error: Failed to run the command"
    cd "$original_dir" # Return to the original directory even in case of an error
    exit 1
fi

echo "Succesfully built node2nix packages at $target_dir, now returning to $original_dir"

# Return to the original directory
cd "$original_dir"
exit 0
