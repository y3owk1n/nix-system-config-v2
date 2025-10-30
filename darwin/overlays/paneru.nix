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
  version = "unstable-e0171d1a53c84dffebc75dce81d3f04a9977ed3a";

  src = fetchFromGitHub {
    owner = "karinushka";
    repo = "paneru";
    rev = "e0171d1a53c84dffebc75dce81d3f04a9977ed3a";
    # rev = "v${finalAttrs.version}";
    sha256 = "sha256-FcswZ9BDh6nxEBxwbwoprLDcNnpTk+JPcPGBldRWysU=";
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

  doCheck = false;
  doInstallCheck = false;
  # nativeInstallCheckInputs = [
  #   versionCheckHook
  # ];
})
