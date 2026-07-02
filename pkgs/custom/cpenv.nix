{
  lib,
  fetchurl,
  stdenv,
  installShellFiles,
  writableTmpDirAsHomeHook,
  versionCheckHook,
  gitUpdater,
}:

# ============================================================================
# Copy ENVs (cpenv)
# ============================================================================
# command-line tool that simplifies the process of copying environment files
# for different projects.

let
  version = "1.15.6";

  archInfo =
    {
      "x86_64-linux" = {
        url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-linux-amd64";
        # use `nix hash convert --hash-algo sha256 <checksum>`
        # even better "awk '{print $1}' <checksum> | xagrs nix hash convert --hash-algo sha256"
        sha256 = "sha256-irWG6iLNxDAgbe7M21iT7cnXyZZlP82miAURK2kzpUg=";
      };
      "aarch64-linux" = {
        url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-linux-arm64";
        sha256 = "sha256-mHxd8eXFDnES1olcw1D+jKH3TeKtHZUb0r0SHzhZwfw=";
      };
      "x86_64-darwin" = {
        url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-darwin-amd64";
        sha256 = "sha256-bb231Ur5ckIniQRupjyObS2SdGdIxOU6slfcrWXlPFc=";
      };
      "aarch64-darwin" = {
        url = "https://github.com/y3owk1n/cpenv/releases/download/v${version}/cpenv-darwin-arm64";
        sha256 = "sha256-mxb5cVZ2/ycAFW/gz+SjX7Ru9FfoguaL08VsXKaX+Ys=";
      };
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

in
stdenv.mkDerivation {
  pname = "cpenv";

  inherit version;

  src = fetchurl {
    inherit (archInfo) url sha256;
  };

  nativeBuildInputs = [
    installShellFiles
    writableTmpDirAsHomeHook
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 $src $out/bin/cpenv
    runHook postInstall
  '';

  postInstall = ''
    if [[ "${lib.boolToString (stdenv.buildPlatform.canExecute stdenv.hostPlatform)}" == "true" ]]; then
      installShellCompletion --cmd cpenv \
        --bash <($out/bin/cpenv completion bash) \
        --fish <($out/bin/cpenv completion fish) \
        --zsh <($out/bin/cpenv completion zsh)
    fi
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.updateScript = gitUpdater {
    url = "https://github.com/y3owk1n/nvs.git";
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "Command-line tool that simplifies the process of copying environment files for different projects";
    homepage = "https://github.com/y3owk1n/cpenv";
    license = licenses.mit;
    mainProgram = "cpenv";
  };

}
