{
  username,
  lib,
  ...
}:

{
  # import sub modules
  imports = [
    ./apps-darwin.nix
    ./packages/atuin.nix
    ./packages/bat.nix
    ./packages/direnv.nix
    ./packages/editorconfig.nix
    ./packages/eza.nix
    ./packages/fish.nix
    ./packages/fzf.nix
    ./packages/gh.nix
    ./packages/ghostty.nix
    ./packages/git.nix
    ./packages/go.nix
    ./packages/gpg.nix
    ./packages/kanata.nix
    ./packages/keyboardcowboy.nix
    ./packages/lazygit.nix
    ./packages/nvim.nix
    ./packages/pass.nix
    ./packages/ripgrep.nix
    ./packages/sesh.nix
    ./packages/skhd.nix
    ./packages/ssh.nix
    ./packages/starship.nix
    ./packages/tmux.nix
    ./custom/cpenv.nix
    ./custom/nvs.nix
    ./custom/cmd.nix
    ./custom/passx.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    # NOTE: Do not delete this! Uncomment this when you want to use spotlight search
    # This will enable spotlight search to index installed apps
    #
    # Source -> https://gist.github.com/Jabb0/1b7ad92e8ab3065ac999c21edc23311f
    #
    activation.copyNixApps = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      # Create directory for the applications
      mkdir -p "$HOME/Applications/Nix-Apps"
      # Remove old entries
      rm -rf "$HOME/Applications/Nix-Apps"/*
      # Get the target of the symlink
      NIXAPPS=$(readlink -f "$HOME/Applications/Home Manager Apps")
      # For each application
      for app_source in "$NIXAPPS"/*; do
        if [ -d "$app_source" ] || [ -L "$app_source" ]; then
            appname=$(basename "$app_source")
            target="$HOME/Applications/Nix-Apps/$appname"

            # Create the basic structure
            mkdir -p "$target"
            mkdir -p "$target/Contents"

            # Copy the Info.plist file
            if [ -f "$app_source/Contents/Info.plist" ]; then
              mkdir -p "$target/Contents"
              cp -f "$app_source/Contents/Info.plist" "$target/Contents/"
            fi

            # Copy icon files
            if [ -d "$app_source/Contents/Resources" ]; then
              mkdir -p "$target/Contents/Resources"
              find "$app_source/Contents/Resources" -name "*.icns" -exec cp -f {} "$target/Contents/Resources/" \;
            fi

            # Symlink the MacOS directory (contains the actual binary)
            if [ -d "$app_source/Contents/MacOS" ]; then
              ln -sfn "$app_source/Contents/MacOS" "$target/Contents/MacOS"
            fi

            # Symlink other directories
            for dir in "$app_source/Contents"/*; do
              dirname=$(basename "$dir")
              if [ "$dirname" != "Info.plist" ] && [ "$dirname" != "Resources" ] && [ "$dirname" != "MacOS" ]; then
                ln -sfn "$dir" "$target/Contents/$dirname"
              fi
            done
          fi
          done
    '';

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";

    shell.enableFishIntegration = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
