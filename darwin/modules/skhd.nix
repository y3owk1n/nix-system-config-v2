{ pkgs, ... }:
{
  # NOTE: Needs to re-grant accessibility permissions after hash updated
  #
  # ensure the service is running
  # launchctl list | grep skhd
  #
  # use the following commands to restart the service
  # launchctl bootout gui/$(id -u)/org.nixos.skhd && \
  # launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nixos.skhd.plist
  services.skhd = {
    enable = true;
    package = pkgs.skhd; # fixed path, won't change every rebuild
    skhdConfig = ''
      hyper - b : open -a Safari
      hyper - t : open -a Ghostty
      hyper - n : open -a Notes
      hyper - m : open -a Mail
      hyper - w : open -a WhatsApp
      hyper - f : open ~
      hyper - s : open -a "System Settings"
    '';
  };
}
