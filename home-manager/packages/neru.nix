{ pkgs, ... }:
{
  programs.neru = {
    enable = true;
    # package = pkgs.neru-source.overrideAttrs (_: {
    #   postPatch = ''
    #     substituteInPlace go.mod \
    #       --replace-fail "go 1.25.2" "go 1.24.9"
    #
    #     # Verify it worked
    #     echo "=== go.mod after patch ==="
    #     grep "^go " go.mod || true
    #   '';
    # });
    config = ''
      [general]
      restore_cursor_position = true

      [hotkeys]
      "Ctrl+F" = "grid -a left_click"
      "Ctrl+G" = "grid"
      "Ctrl+S" = "action scroll"

      [hints]
      enabled = false

      [grid]
      font_family = "JetBrainsMonoNLNFP-ExtraBold"

      sublayer_keys = "gcrhtnmwv"

      [action]
      left_click_key = "h"
      middle_click_key = "t"
      right_click_key = "n"
      mouse_down_key = "c"
      mouse_up_key = "r"

      [smooth_cursor]
      move_mouse_enabled = true
      steps = 10
      delay = 1

      [logging]
      log_level = "info"
      disable_file_logging = true
    '';
  };
}
