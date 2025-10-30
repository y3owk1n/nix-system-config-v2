{
  fetchzip,
  gitUpdater,
  installShellFiles,
  stdenv,
  versionCheckHook,
}:

let
  appName = "HyprSpace.app";
  version = "0.2.0";
in
stdenv.mkDerivation {
  pname = "hyprspace";

  inherit version;

  src = fetchzip {
    url = "https://github.com/BarutSRB/HyprSpace/releases/download/v${version}/HyprSpace-v${version}.zip";
    sha256 = "sha256-kiUEk1yovV5V6riaQOjlQXSXI04/HuFzQZeRA+A4HHM=";
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
    installManPage manpage/*
    installShellCompletion --bash shell-completion/bash/aerospace
    installShellCompletion --fish shell-completion/fish/aerospace.fish
    installShellCompletion --zsh  shell-completion/zsh/_aerospace
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.updateScript = gitUpdater {
    url = "https://github.com/BarutSRB/HyprSpace.git";
    rev-prefix = "v";
  };

  meta = {
    mainProgram = "hyprspace";
  };
}
