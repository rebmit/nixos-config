{
  config,
  pkgs,
  lib,
  ...
}:
let
  args = {
    inherit config pkgs lib;
  };
in
{
  imports = lib.singleton ./_default.nix;

  programs.waybar.settings = lib.singleton (
    {
      position = "top";
      modules-left = [
        "custom/nixos"
        "niri/workspaces"
        "niri/window"
      ];
      modules-right = [
        "network"
        "pulseaudio"
        "clock"
        "tray"
      ];
    }
    // (import ./_common.nix args)
  );
}
