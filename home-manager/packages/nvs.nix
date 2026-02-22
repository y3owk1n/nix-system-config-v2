{ pkgs, ... }:
{
  programs.nvs = {
    enable = true;
    package = pkgs.nvs;
    # package = pkgs.nvs-source;
    # package = pkgs.nvs-source.overrideAttrs (_: {
    #   postPatch = ''
    #     substituteInPlace go.mod \
    #       --replace-fail "go 1.26.0" "go 1.25.5"
    #
    #     # Verify it worked
    #     echo "=== go.mod after patch ==="
    #     grep "^go " go.mod || true
    #   '';
    # });
    enableAutoSwitch = false;
    useGlobalCache = true;
  };
}
