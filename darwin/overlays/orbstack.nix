{
  fetchurl,
  stdenv,
}:
let
  appName = "OrbStack.app";
  version = "2.0.3";
  build = "19876";
in
stdenv.mkDerivation {
  pname = "orbstack";
  inherit version;

  src = fetchurl {
    url = "https://cdn-updates.orbstack.dev/arm64/OrbStack_v${version}_${build}_arm64.dmg";
    sha256 = "sha256-3Ppc0zWEgR/nTS7R9uAkUYYgYu5q2TWmfd3evT+Z8g4=";
  };

  sourceRoot = ".";

  unpackCmd = ''
    echo "Creating temp directory"
    mnt=$(TMPDIR=/tmp mktemp -d -t nix-XXXXXXXXXX)
    function finish {
      echo "Ejecting temp directory"
      /usr/bin/hdiutil detach $mnt -force
      rm -rf $mnt
    }
    trap finish EXIT
    echo "Mounting DMG file into \"$mnt\""
    yes | PAGER=cat /usr/bin/hdiutil attach -nobrowse -noverify -noautoopen -mountpoint $mnt $curSrc
    echo 'Copying extracted content'
    cp -a $mnt/${appName} $PWD/
  '';

  installPhase = ''
    mkdir -p "$out/Applications"
    mv ${appName} $out/Applications/

    # Create bin directory and symlink binaries
    mkdir -p "$out/bin"
    ln -s "$out/Applications/${appName}/Contents/MacOS/bin/orb" "$out/bin/orb"
    ln -s "$out/Applications/${appName}/Contents/MacOS/bin/orbctl" "$out/bin/orbctl"

    # Install shell completions
    mkdir -p "$out/share/bash-completion/completions"
    ln -s "$out/Applications/${appName}/Contents/Resources/completions/bash/orbctl.bash" \
      "$out/share/bash-completion/completions/orbctl"

    mkdir -p "$out/share/fish/vendor_completions.d"
    ln -s "$out/Applications/${appName}/Contents/Resources/completions/fish/orbctl.fish" \
      "$out/share/fish/vendor_completions.d/orbctl.fish"

    mkdir -p "$out/share/zsh/site-functions"
    ln -s "$out/Applications/${appName}/Contents/Resources/completions/zsh/_orb" \
      "$out/share/zsh/site-functions/_orb"
    ln -s "$out/Applications/${appName}/Contents/Resources/completions/zsh/_orbctl" \
      "$out/share/zsh/site-functions/_orbctl"
  '';
}
