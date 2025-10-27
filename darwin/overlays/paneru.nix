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
  pname = "paneru";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "karinushka";
    repo = "paneru";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-cVNqqTVzRWAK+uGYFRZo0aWroysOZsa1z6GKwM6J4Xo=";
  };

  cargoHash = "sha256-LKQ0pjODOmcMlxlmEUMu9NlS2GCDF4shlOLie+9Hdv4=";

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
