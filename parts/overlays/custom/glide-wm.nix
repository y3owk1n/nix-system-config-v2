{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
  nix-update-script,
}:

# ============================================================================
# Glide Window Manager Overlay
# ============================================================================
# Custom build of Glide tiling window manager from git main branch

let
  rev = "fe9576954716f7f5d83f62e3f8c1f40ce953d4c3";
  shortHash = lib.substring 0 7 rev;
  pversion = "main-${shortHash}";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "glide";
  version = pversion;

  src = fetchFromGitHub {
    owner = "glide-wm";
    repo = "glide";
    inherit rev;
    # rev = "v${finalAttrs.version}";
    sha256 = "sha256-S3nWI8T7V4otPwaLRJ68mroYd70+ptFFj4Yd9nfml2s=";
  };

  cargoHash = "sha256-3KZNbJsaW3ulsEU8wiw834I4P3g7Jn7w3nlPfbKr8K4=";

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
    	mkdir -p $out/Applications/Glide.app/Contents/MacOS
    	mkdir -p $out/Applications/Glide.app/Contents/Resources

    	cp $out/bin/glide $out/Applications/Glide.app/Contents/MacOS/Glide
    	cp $out/bin/glide_server $out/Applications/Glide.app/Contents/MacOS/GlideServer

    	cat > $out/Applications/Glide.app/Contents/Info.plist <<EOF
    	<?xml version="1.0" encoding="UTF-8"?>
    	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    		"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    	<plist version="1.0">
    	<dict>
    		<key>CFBundleName</key>
    		<string>Glide</string>

    		<key>CFBundleExecutable</key>
    		<string>glide_server</string>

    		<key>CFBundleIdentifier</key>
    		<string>com.glidewm.glide</string>

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

    	echo "✅ Glide.app bundle created at $out/Applications/Glide.app"
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    platforms = platforms.darwin;
    mainProgram = "glide";
  };
})
