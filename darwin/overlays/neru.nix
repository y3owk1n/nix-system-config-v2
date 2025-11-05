{
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  writableTmpDirAsHomeHook,
  lib,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "neru";
  # version = "1.3.0";
  version = "unstable-latest-ce753d99a7bac47e4cc35465939b2ed8c70a6877";
  commitHash = "ce753d99a7bac47e4cc35465939b2ed8c70a6877";

  src = fetchFromGitHub {
    owner = "y3owk1n";
    repo = "neru";
    # tag = "v${finalAttrs.version}";
    rev = "${finalAttrs.commitHash}";
    hash = "sha256-++FDeY2AF/qq4j/U8KOR6XzBIr0jQcA95kl7Y90cv/U=";
  };

  vendorHash = "sha256-x5NB18fP8ERIB5qeMAMyMnSoDEF2+g+NoJKrC+kIj+k=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/y3owk1n/neru/internal/cli.Version=${finalAttrs.version}"
  ];

  # Completions
  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook
  ];
  postInstall = ''
    # install shell completions
    if ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) "true"}; then
      installShellCompletion --cmd neru \
        --bash <($out/bin/neru completion bash) \
        --fish <($out/bin/neru completion fish) \
        --zsh <($out/bin/neru completion zsh)
    fi

    # Create a simple .app bundle on the fly
    mkdir -p $out/Applications
    mkdir -p $out/Applications/Neru.app/Contents/MacOS
    mkdir -p $out/Applications/Neru.app/Contents/Resources

    cp $out/bin/neru $out/Applications/Neru.app/Contents/MacOS/neru

    cat > $out/Applications/Neru.app/Contents/Info.plist <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleName</key><string>Neru</string>
      <key>CFBundleExecutable</key><string>neru</string>
      <key>CFBundleIdentifier</key><string>com.y3owk1n.neru</string>
      <key>CFBundleVersion</key><string>${finalAttrs.version}</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>LSUIElement</key><true/> <!-- hides dock icon, good for menubar apps -->
      <key>NSAppleEventsUsageDescription</key><string>Used for automation</string>
      <key>NSMicrophoneUsageDescription</key><string>Used for accessibility control</string>
      <key>NSAccessibilityUsageDescription</key><string>Requires accessibility access</string>
    </dict>
    </plist>
    EOF

    echo "✅ Neru.app bundle created at $out/Applications/Neru.app"
  '';

  passthru = {
    updateScript = nix-update-script { };
  };
})
