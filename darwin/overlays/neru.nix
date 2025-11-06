# {
#   fetchzip,
#   gitUpdater,
#   installShellFiles,
#   stdenv,
#   versionCheckHook,
#   lib,
# }:
#
# let
#   appName = "Neru.app";
#   version = "1.5.1";
# in
# stdenv.mkDerivation {
#   pname = "neru";
#
#   inherit version;
#
#   src = fetchzip {
#     url = "https://github.com/y3owk1n/neru/releases/download/v${version}/neru-darwin-arm64.zip";
#     sha256 = "sha256-IwiyM0NboSrBGDiIsM5uzNxuT6+yer/86gKNKBZ4RAI=";
#     stripRoot = false;
#   };
#
#   nativeBuildInputs = [ installShellFiles ];
#
#   installPhase = ''
#     runHook preInstall
#     mkdir -p $out/Applications
#     mv ${appName} $out/Applications
#     cp -R bin $out
#     mkdir -p $out/share
#     runHook postInstall
#   '';
#
#   postInstall = ''
#     if ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) "true"}; then
#       installShellCompletion --cmd neru \
#         --bash <($out/bin/neru completion bash) \
#         --fish <($out/bin/neru completion fish) \
#         --zsh <($out/bin/neru completion zsh)
#     fi
#   '';
#
#   doInstallCheck = true;
#   nativeInstallCheckInputs = [
#     versionCheckHook
#   ];
#
#   passthru.updateScript = gitUpdater {
#     url = "https://github.com/y3owk1n/neru.git";
#     rev-prefix = "v";
#   };
#
#   meta = {
#     mainProgram = "neru";
#   };
# }

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
  version = "unstable-latest-53e0557552052b804427f859dca430e2608bcec2";
  commitHash = "53e0557552052b804427f859dca430e2608bcec2";

  src = fetchFromGitHub {
    owner = "y3owk1n";
    repo = "neru";
    rev = "${finalAttrs.commitHash}";
    hash = "sha256-5YqaDCkTEj+2C356aS1t2nilMYs6ByrASTG0Ck/zDa8=";
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

    cp $out/bin/neru $out/Applications/Neru.app/Contents/MacOS/Neru

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
      <key>LSUIElement</key><true/>
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
