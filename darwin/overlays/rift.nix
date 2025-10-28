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
  version = "0.0.10.1";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-oTLfMvvVIj2KM/v44Abe2/54wR3COnvXpW/0L1yocEs=";
  };

  cargoHash = "sha256-9pKA9vKfW3zIYvbrIbld/X26blmupdZm+SmmQOGoeJI=";

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
