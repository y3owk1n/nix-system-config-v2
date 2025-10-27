{
  stdenv,
  lib,
  apple-sdk_13,
  darwinMinVersionHook,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
  writeShellScriptBin,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rift";
  version = "0.0.9";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-Dd8eBeH8lH88CMmIXrTYE4UlgdNNn6W3j2PhgbUUhBE=";
  };

  cargoHash = "sha256-+DWieSNh7B2EW9AvAT97Q6wSE+T4h5McVW6X6lqDA6Y=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_13
    (darwinMinVersionHook "13.0")
  ];

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (writeShellScriptBin "sw_vers" ''
      echo 'ProductVersion: 13.0'
    '')
  ];

  doInstallCheck = false;
  # nativeInstallCheckInputs = [
  #   versionCheckHook
  # ];
})
