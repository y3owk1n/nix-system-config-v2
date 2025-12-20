{ pkgs, ... }:
{
  home.packages = with pkgs; [
    graphite-cli
  ];

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      editor = "nvim";
      git_protocol = "ssh";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
    };
  };
}
