{ ... }:
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    # enableTransience = true;
    settings = {
      add_newline = false;
      # Minimal left prompt
      format = "$directory$character";
      # Move everything to the right
      right_format = "$all";
      command_timeout = 1000;
      palette = "catppuccin_macchiato";
      palettes = {
        catppuccin_macchiato = {
          rosewater = "#f4dbd6";
          flamingo = "#f0c6c6";
          pink = "#f5bde6";
          mauve = "#c6a0f6";
          red = "#ed8796";
          maroon = "#ee99a0";
          peach = "#f5a97f";
          yellow = "#eed49f";
          green = "#a6da95";
          teal = "#8bd5ca";
          sky = "#91d7e3";
          sapphire = "#7dc4e4";
          blue = "#8aadf4";
          lavender = "#b7bdf8";
          text = "#cad3f5";
          subtext1 = "#b8c0e0";
          subtext0 = "#a5adcb";
          overlay2 = "#939ab7";
          overlay1 = "#8087a2";
          overlay0 = "#6e738d";
          surface2 = "#5b6078";
          surface1 = "#494d64";
          surface0 = "#363a4f";
          base = "#24273a";
          mantle = "#1e2030";
          crust = "#181926";
        };
      };
      aws = {
        disabled = true;
      };
      azure = {
        disabled = true;
      };
      battery = {
        disabled = true;
      };
      buf = {
        disabled = true;
      };
      c = {
        disabled = true;
      };
      cmake = {
        disabled = true;
      };
      cobol = {
        disabled = true;
      };
      conda = {
        disabled = true;
      };
      crystal = {
        disabled = true;
      };
      daml = {
        disabled = true;
      };
      dart = {
        disabled = true;
      };
      direnv = {
        disabled = true;
      };
      dotnet = {
        disabled = true;
      };
      elixir = {
        disabled = true;
      };
      elm = {
        disabled = true;
      };
      erlang = {
        disabled = true;
      };
      fennel = {
        disabled = true;
      };
      fossil_branch = {
        disabled = true;
      };
      fossil_metrics = {
        disabled = true;
      };
      gcloud = {
        disabled = true;
      };
      gleam = {
        disabled = true;
      };
      golang = {
        disabled = true;
      };
      guix_shell = {
        disabled = true;
      };
      gradle = {
        disabled = true;
      };
      haskell = {
        disabled = true;
      };
      haxe = {
        disabled = true;
      };
      helm = {
        disabled = true;
      };
      java = {
        disabled = true;
      };
      jobs = {
        disabled = true;
      };
      julia = {
        disabled = true;
      };
      kotlin = {
        disabled = true;
      };
      kubernetes = {
        disabled = true;
      };
      meson = {
        disabled = true;
      };
      hg_branch = {
        disabled = true;
      };
      nats = {
        disabled = true;
      };
      nim = {
        disabled = true;
      };
      ocaml = {
        disabled = true;
      };
      odin = {
        disabled = true;
      };
      opa = {
        disabled = true;
      };
      openstack = {
        disabled = true;
      };
      perl = {
        disabled = true;
      };
      php = {
        disabled = true;
      };
      pijul_channel = {
        disabled = true;
      };
      pulumi = {
        disabled = true;
      };
      purescript = {
        disabled = true;
      };
      python = {
        disabled = true;
      };
      quarto = {
        disabled = true;
      };
      rlang = {
        disabled = true;
      };
      raku = {
        disabled = true;
      };
      red = {
        disabled = true;
      };
      ruby = {
        disabled = true;
      };
      scala = {
        disabled = true;
      };
      shlvl = {
        disabled = true;
      };
      singularity = {
        disabled = true;
      };
      solidity = {
        disabled = true;
      };
      spack = {
        disabled = true;
      };
      terraform = {
        disabled = true;
      };
      time = {
        disabled = true;
      };
      typst = {
        disabled = true;
      };
      vagrant = {
        disabled = true;
      };
      vlang = {
        disabled = true;
      };
      vcsh = {
        disabled = true;
      };
      zig = {
        disabled = true;
      };
      character = {
        error_symbol = "[➜](bold red)";
        success_symbol = "[➜](bold green)";
        vimcmd_replace_one_symbol = "[](bold purple)";
        vimcmd_replace_symbol = "[](bold purple)";
        vimcmd_symbol = "[](bold green)";
        vimcmd_visual_symbol = "[](bold yellow)";

      };
      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };
      git_status = {
        ahead = "⇡$count";
        behind = "⇣$count";
        deleted = "✘$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        modified = "!$count";
        renamed = "»$count";
        staged = "+$count";
        stashed = "\\$$count";
        untracked = "?$count";
      };
    };
  };
}
