{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
in
{
  # TODO: read-only etc
  system.etc.overlay.enable = mkIf (!config.boot.isContainer) true;
}
