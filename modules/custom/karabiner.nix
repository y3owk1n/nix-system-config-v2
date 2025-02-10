let
  pkgs = import <nixpkgs> { };

  version = "5.0.0";
  pkgUrl = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${version}/Karabiner-DriverKit-VirtualHIDDevice-${version}.pkg";

  karabiner_driver_kit = pkgs.fetchurl {
    url = pkgUrl;
    sha256 = "sha256-hKi2gmIdtjl/ZaS7RPpkpSjb+7eT0259sbUUbrn5mMc="; # Ensure this SHA-256 hash is correct
  };

  application_path = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";
in
{
  system.activationScripts.postUserActivation.text = ''
    	echo "Checking if Karabiner-VirtualHIDDevice-Manager exists..."

    	if [ -f /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager ]; then
    		echo "Karabiner-VirtualHIDDevice-Manager exists. Activating..."
    		sudo ${application_path} activate
    	else
    		echo "Karabiner-VirtualHIDDevice-Manager not found. Installing..."

    		# Install the package using the installer command
    		echo "Running installer for Karabiner-VirtualHIDDevice..."
    		sudo /usr/sbin/installer -pkg ${karabiner_driver_kit} -target /

    		# Check installation result
    		if /usr/sbin/installer -pkg ${karabiner_driver_kit} -target /; then
    			echo "Installation completed successfully. Activating..."
    			sudo ${application_path} activate
    		else
    			echo "Installation failed."
    		fi
    	fi

    	echo "Karabiner installation script completed."
  '';
}
