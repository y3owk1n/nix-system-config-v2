{
  stdenv,
  lib,
  apple-sdk_13,
  darwinMinVersionHook,
  rustPlatform,
  fetchFromGitHub,
  writeShellScriptBin,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "paneru";
  version = "unstable-2025-10-29";

  src = fetchFromGitHub {
    owner = "y3owk1n";
    repo = "paneru";
    rev = "0ac348a993c340df0948fa1afada3e60bf0bd45f";
    sha256 = "sha256-QgMPHS9MaNNF3WmnF5Qmrsjg6v2xeiI+/1+0NImoO0M=";
  };

  cargoHash = "sha256-Bgb1gLls0PJUBY6PCoqnAjXkUntXphKOi/LW6PpA/4k=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_13
    (darwinMinVersionHook "13.0")
  ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: 13.0'
    '')
  ];

  doCheck = false; # ⬅ Disable Rust tests
  doInstallCheck = false;
  # nativeInstallCheckInputs = [
  #   versionCheckHook
  # ];
})
