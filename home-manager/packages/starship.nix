{ ... }:
{
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      command_timeout = 3000; # set longer to give it some time to warmup
      character = {
        error_symbol = "[](bold red)";
        success_symbol = "[](bold green)";
        vimcmd_replace_one_symbol = "[](bold purple)";
        vimcmd_replace_symbol = "[](bold purple)";
        vimcmd_symbol = "[](bold green)";
        vimcmd_visual_symbol = "[](bold yellow)";
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
        ignore_submodules = true;
      };

      # symbols
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";
      golang.symbol = "󰟓 ";
      lua.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";

      # enable
      direnv.disabled = false;

      # disable
      aws.disabled = true;
      azure.disabled = true;
      battery.disabled = true;
      buf.disabled = true;
      c.disabled = true;
      cpp.disabled = true;
      cmake.disabled = true;
      cobol.disabled = true;
      conda.disabled = true;
      crystal.disabled = true;
      daml.disabled = true;
      dart.disabled = true;
      dotnet.disabled = true;
      elixir.disabled = true;
      elm.disabled = true;
      env_var.disabled = true;
      erlang.disabled = true;
      fennel.disabled = true;
      fossil_branch.disabled = true;
      fossil_metrics.disabled = true;
      gcloud.disabled = true;
      git_metrics.disabled = true;
      gleam.disabled = true;
      guix_shell.disabled = true;
      gradle.disabled = true;
      haskell.disabled = true;
      haxe.disabled = true;
      helm.disabled = true;
      java.disabled = true;
      julia.disabled = true;
      kotlin.disabled = true;
      kubernetes.disabled = true;
      localip.disabled = true;
      memory_usage.disabled = true;
      meson.disabled = true;
      hg_branch.disabled = true;
      mise.disabled = true;
      mojo.disabled = true;
      nats.disabled = true;
      netns.disabled = true;
      nim.disabled = true;
      ocaml.disabled = true;
      odin.disabled = true;
      opa.disabled = true;
      openstack.disabled = true;
      os.disabled = true;
      package.disabled = true;
      perl.disabled = true;
      php.disabled = true;
      pijul_channel.disabled = true;
      pixi.disabled = true;
      pulumi.disabled = true;
      purescript.disabled = true;
      python.disabled = true;
      quarto.disabled = true;
      rlang.disabled = true;
      raku.disabled = true;
      red.disabled = true;
      ruby.disabled = true;
      rust.disabled = true;
      scala.disabled = true;
      shell.disabled = true;
      shlvl.disabled = true;
      singularity.disabled = true;
      solidity.disabled = true;
      spack.disabled = true;
      status.disabled = true;
      sudo.disabled = true;
      swift.disabled = true;
      terraform.disabled = true;
      time.disabled = true;
      typst.disabled = true;
      vagrant.disabled = true;
      vlang.disabled = true;
      vcsh.disabled = true;
      zig.disabled = true;
    };
  };
  programs.fish.functions.starship_transient_prompt_func = {
    description = "Starship transient prompt";
    body = ''
      starship module character
    '';
  };
}
