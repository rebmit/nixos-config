{
  config,
  pkgs,
  lib,
  ...
}:
let
  defaultMode = pkgs.writeText "darkman-default-mode" "light";
in
{
  services.darkman.enable = true;

  home.globalPersistence.directories = [ ".cache/darkman" ];

  systemd.user.tmpfiles.rules = [
    "C %h/.cache/darkman/mode.txt - - - - ${defaultMode}"
    "z %h/.cache/darkman/mode.txt 644 - - -"
  ];

  home.packages = with pkgs; [
    (writeShellApplication {
      name = "toggle-theme";
      runtimeInputs = lib.singleton config.services.darkman.package;
      text = ''
        darkman toggle
      '';
    })
  ];

  home.activation.restartDarkman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${config.systemd.user.systemctlPath} --user is-active darkman; then
      ${config.systemd.user.systemctlPath} --user restart darkman
    fi
  '';

  systemd.user.services.darkman.Unit = {
    After = [ "graphical-session.target" ];
    Requisite = [ "graphical-session.target" ];
  };
}
