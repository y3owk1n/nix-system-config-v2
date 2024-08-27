let
  pkgs = import <nixpkgs> { };

  version = "3.1.0";
  pkgUrl = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${version}/Karabiner-DriverKit-VirtualHIDDevice-${version}.pkg";

  karabiner_driver_kit = pkgs.fetchurl {
    url = pkgUrl;
    sha256 = "178z7vhcymrmkxpgpvy11j5rcjglsia5n4kb2mpwfbdi8zmzy210"; # Ensure this SHA-256 hash is correct
  };
in
{
  system.activationScripts.postUserActivation.text = ''
    echo "Checking if Karabiner-VirtualHIDDevice-Manager exists..."

    if [ -f /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager ]; then
      echo "Karabiner-VirtualHIDDevice-Manager exists. Activating..."
      /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
    else
      echo "Karabiner-VirtualHIDDevice-Manager not found. Installing..."
      
      # Install the package using the installer command
      echo "Running installer for Karabiner-VirtualHIDDevice..."
      sudo /usr/sbin/installer -pkg ${karabiner_driver_kit} -target /
      
      # Check installation result
      if [ $? -eq 0 ]; then
        echo "Installation completed successfully. Activating..."
        /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
      else
        echo "Installation failed."
      fi
    fi

    echo "Karabiner installation script completed."
  '';
}
