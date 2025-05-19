{ pkgs, ... }:
let
  version = "5.0.0";
  pkgUrl = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${version}/Karabiner-DriverKit-VirtualHIDDevice-${version}.pkg";

  karabiner_driver_kit = pkgs.fetchurl {
    url = pkgUrl;
    sha256 = "sha256-hKi2gmIdtjl/ZaS7RPpkpSjb+7eT0259sbUUbrn5mMc="; # Ensure this SHA-256 hash is correct
  };

  application_path = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager";
  plist_path = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/Info.plist";
in
{
  system.activationScripts.postActivation.text = ''
    	echo "Checking if Karabiner-VirtualHIDDevice-Manager exists..."

    	if [ -f "${application_path}" ]; then
    		echo "Karabiner-VirtualHIDDevice-Manager exists. Checking version..."

    		# Get installed version
    		installed_version=$(/usr/bin/defaults read "${plist_path}" CFBundleVersion)
    		echo "Installed version: $installed_version"

    		if [ "$installed_version" = "${version}" ]; then
    			echo "Karabiner is up-to-date (version ${version}). Activating..."
    			sudo "${application_path}" activate
    		else
    			echo "Karabiner version mismatch (expected ${version}, found $installed_version). Reinstalling..."
    			if sudo /usr/sbin/installer -pkg "${karabiner_driver_kit}" -target /; then
    				echo "Installation completed successfully. Activating..."
    				sudo "${application_path}" deactivate
    				sudo "${application_path}" activate
    			else
    				echo "Installation failed."
    			fi
    		fi
    	else
    		echo "Karabiner-VirtualHIDDevice-Manager not found. Installing..."

    		# Install the package
    		if sudo /usr/sbin/installer -pkg "${karabiner_driver_kit}" -target /; then
    			echo "Installation completed successfully. Activating..."
    			sudo "${application_path}" activate
    		else
    			echo "Installation failed."
    		fi
    	fi

    	echo "Karabiner installation script completed."
  '';
}
