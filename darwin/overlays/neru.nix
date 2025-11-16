{
  fetchzip,
  gitUpdater,
  installShellFiles,
  stdenv,
  versionCheckHook,
  lib,
}:

let
  appName = "Neru.app";
  version = "1.8.0";
in
stdenv.mkDerivation {
  pname = "neru";

  inherit version;

  src = fetchzip {
    url = "https://github.com/y3owk1n/neru/releases/download/v${version}/neru-darwin-arm64.zip";
    sha256 = "sha256-ebaSQMP6ek/Ujr9Rl4Wfevl7lM9t4ln8Kritx5HoUmM=";
    stripRoot = false;
  };

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    mv ${appName} $out/Applications
    cp -R bin $out
    mkdir -p $out/share
    runHook postInstall
  '';

  postInstall = ''
    if ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) "true"}; then
      installShellCompletion --cmd neru \
        --bash <($out/bin/neru completion bash) \
        --fish <($out/bin/neru completion fish) \
        --zsh <($out/bin/neru completion zsh)
    fi
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.updateScript = gitUpdater {
    url = "https://github.com/y3owk1n/neru.git";
    rev-prefix = "v";
  };

  meta = {
    mainProgram = "neru";
  };
}

# {
#   stdenv,
#   buildGoModule,
#   fetchFromGitHub,
#   installShellFiles,
#   writableTmpDirAsHomeHook,
#   lib,
#   nix-update-script,
# }:
# buildGoModule (finalAttrs: {
#   pname = "neru";
#   version = "unstable-60910774";
#   commitHash = "609107742cfe8f7ff40e959542161dd87c9d1e37";
#
#   src = fetchFromGitHub {
#     owner = "y3owk1n";
#     repo = "neru";
#     rev = "${finalAttrs.commitHash}";
#     hash = "sha256-/u53lEzanEmRPGwRZhQt8HsjM2LZQUZJ/yRULZ1NVf4=";
#   };
#
#   vendorHash = "sha256-5P2+SJYjodrfyWacXVM+j0DF1Y5HuJh1p5fIizKH4K8=";
#
#   ldflags = [
#     "-s"
#     "-w"
#     "-X github.com/y3owk1n/neru/internal/cli.Version=${finalAttrs.version}"
#   ];
#
#   # Completions
#   nativeBuildInputs = [
#     installShellFiles
#     writableTmpDirAsHomeHook
#   ];
#
#   subPackages = [ "cmd/neru" ];
#
#   # Fix go version requirement
#   postPatch = ''
#     substituteInPlace go.mod \
#       --replace-fail "go 1.25.2" "go 1.25.1"
#
#     # Verify it worked
#     echo "=== go.mod after patch ==="
#     grep "^go " go.mod || true
#   '';
#
#   # Allow Go to use any available toolchain
#   preBuild = ''
#     export GOTOOLCHAIN=auto
#   '';
#
#   postInstall = ''
#     # install shell completions
#     if ${lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) "true"}; then
#       installShellCompletion --cmd neru \
#         --bash <($out/bin/neru completion bash) \
#         --fish <($out/bin/neru completion fish) \
#         --zsh <($out/bin/neru completion zsh)
#     fi
#
#     # Create a simple .app bundle on the fly
#     mkdir -p $out/Applications
#     mkdir -p $out/Applications/Neru.app/Contents/MacOS
#     mkdir -p $out/Applications/Neru.app/Contents/Resources
#
#     cp $out/bin/neru $out/Applications/Neru.app/Contents/MacOS/Neru
#
#     cat > $out/Applications/Neru.app/Contents/Info.plist <<EOF
#     <?xml version="1.0" encoding="UTF-8"?>
#     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
#         "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#     <plist version="1.0">
#     <dict>
#       <key>CFBundleName</key><string>Neru</string>
#       <key>CFBundleExecutable</key><string>neru</string>
#       <key>CFBundleIdentifier</key><string>com.y3owk1n.neru</string>
#       <key>CFBundleVersion</key><string>${finalAttrs.version}</string>
#       <key>CFBundlePackageType</key><string>APPL</string>
#       <key>LSUIElement</key><true/>
#       <key>NSAppleEventsUsageDescription</key><string>Used for automation</string>
#       <key>NSMicrophoneUsageDescription</key><string>Used for accessibility control</string>
#       <key>NSAccessibilityUsageDescription</key><string>Requires accessibility access</string>
#     </dict>
#     </plist>
#     EOF
#
#     echo "✅ Neru.app bundle created at $out/Applications/Neru.app"
#   '';
#
#   passthru = {
#     updateScript = nix-update-script { };
#   };
# })
