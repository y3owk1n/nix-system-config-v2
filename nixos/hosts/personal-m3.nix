{
  pkgs,
  username,
  config,
  ...
}:
{
  imports = [
    ../shared/core.nix
  ];

  users.users."${username}" = {
    home = "/home/${username}";
    description = username;
    shell = pkgs.fish;
  };

  # Set your time zone.
  time.timeZone = "Asia/Kuala_Lumpur";

  # Fonts
  fonts = {
    packages = with pkgs; [
      poppins
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
  };
}
