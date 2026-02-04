{
  stdenv,
  lib,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
  nix-update-script,
  imagemagick,
  libicns,
}:

# ============================================================================
# Glide Window Manager Overlay
# ============================================================================
# Custom build of Glide tiling window manager from git main branch

let
  rev = "7a23bb816be071df72af7fed2652c6b182328998";
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
    sha256 = "sha256-nI9OWzd1K9df1RZxu1ikiF2XV4rmfYo6Q3KyAFZq5Vw=";
  };

  cargoHash = "sha256-rt9Fd0iP6NjDY1wH873MPN44z/2sfs79zQYcvjbHD+8=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    imagemagick
    libicns # Provides png2icns
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: ${stdenv.hostPlatform.darwinMinVersion}'
    '')
  ];

  doInstallCheck = false;
  doCheck = false;

  postInstall = ''
    # Create a simple .app bundle on the fly
    mkdir -p $out/Applications/Glide.app/Contents/{MacOS,Resources}

    cp $out/bin/glide $out/Applications/Glide.app/Contents/MacOS/glide
    cp $out/bin/glide_server $out/Applications/Glide.app/Contents/MacOS/glide_server

    # Generate .icns from PNG using libicns
    ICONDIR=$(mktemp -d)
    SRC_ICON=${finalAttrs.src}/assets/app_icon-128x128@2x.png

    # Generate icon sizes for png2icns
    # png2icns expects specific sizes
    for size in 16 32 48 128 256 512; do
      magick "$SRC_ICON" -resize ''${size}x''${size} "$ICONDIR/icon_''${size}x''${size}.png"
    done

    # Create .icns file from PNGs
    png2icns $out/Applications/Glide.app/Contents/Resources/Glide.icns "$ICONDIR"/icon_*.png

    cat > $out/Applications/Glide.app/Contents/Info.plist <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleDevelopmentRegion</key>
      <string>English</string>

      <key>CFBundleDisplayName</key>
      <string>Glide</string>

      <key>CFBundleExecutable</key>
      <string>glide_server</string>

      <key>CFBundleIconFile</key>
      <string>Glide</string>

      <key>CFBundleIdentifier</key>
      <string>org.glidewm.glide</string>

      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>

      <key>CFBundleName</key>
      <string>Glide</string>

      <key>CFBundlePackageType</key>
      <string>APPL</string>

      <key>CFBundleVersion</key>
      <string>${finalAttrs.version}</string>

      <key>CSResourcesFileMapped</key>
      <true/>

      <key>LSRequiresCarbon</key>
      <true/>

      <key>NSHighResolutionCapable</key>
      <true/>

      <key>LSUIElement</key>
      <true/>

      <key>NSAppleEventsUsageDescription</key>
      <string>Glide needs to manage and rearrange windows.</string>

      <key>NSAccessibilityUsageDescription</key>
      <string>Glide needs accessibility access to manage windows.</string>
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
