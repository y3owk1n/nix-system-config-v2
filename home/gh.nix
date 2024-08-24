{ ... }:
{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      # aliases = {
      #   co = "pr checkout";
      # };
      editor = "nvim";
      git_protocol = "ssh";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
    };
  };
}
