{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
  nix-update-script,
}:

# ============================================================================
# Rift Window Manager Overlay
# ============================================================================
# Custom build of Rift tiling window manager from git main branch

let
  rev = "3c43102447a0b2ff18a35f63a461558ebb35c68c";
  shortHash = lib.substring 0 7 rev;
  pversion = "main-${shortHash}";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rift";
  version = pversion;

  src = fetchFromGitHub {
    # owner = "acsandmann";
    owner = "y3owk1n";
    repo = "rift";
    inherit rev;
    # rev = "v${finalAttrs.version}";
    sha256 = "sha256-GFekM79NeRVH/BoZAb7FaAeqYFNalzeHbFJy7p8NQnQ=";
  };

  cargoHash = "sha256-A0huWauj3Ltnw39jFft6pyYUVcNK+lu89ZlVQl/aRZg=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: ${stdenv.hostPlatform.darwinMinVersion}'
    '')
  ];

  doInstallCheck = false;
  doCheck = false;

  postInstall = ''
    	# Create a simple .app bundle on the fly
    	mkdir -p $out/Applications
    	mkdir -p $out/Applications/Rift.app/Contents/MacOS
    	mkdir -p $out/Applications/Rift.app/Contents/Resources

    	cp $out/bin/rift $out/Applications/Rift.app/Contents/MacOS/Rift

    	cat > $out/Applications/Rift.app/Contents/Info.plist <<EOF
    	<?xml version="1.0" encoding="UTF-8"?>
    	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    		"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    	<plist version="1.0">
    	<dict>
    		<key>CFBundleName</key>
    		<string>Rift</string>

    		<key>CFBundleExecutable</key>
    		<string>rift</string>

    		<key>CFBundleIdentifier</key>
    		<string>git.acsandmann.rift</string>

    		<key>CFBundleVersion</key>
    		<string>${finalAttrs.version}</string>

    		<key>CFBundlePackageType</key>
    		<string>APPL</string>

    		<key>LSUIElement</key>
    		<true/>

    		<key>NSAppleEventsUsageDescription</key>
    		<string>Used for automation</string>

    		<key>NSMicrophoneUsageDescription</key>
    		<string>Used for accessibility control</string>

    		<key>NSAccessibilityUsageDescription</key>
    		<string>Requires accessibility access</string>
    	</dict>
    	</plist>
    	EOF

    	echo "✅ Rift.app bundle created at $out/Applications/Rift.app"
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    platforms = platforms.darwin;
    mainProgram = "rift";
  };
})
