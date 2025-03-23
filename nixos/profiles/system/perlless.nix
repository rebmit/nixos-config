{ config, lib, ... }:
{
  # TODO: read-only etc
  system.etc.overlay.enable = lib.mkIf (!config.boot.isContainer) true;

  services.userborn = {
    enable = true;

    # TODO: move to /var/lib/userborn
    # TODO: statically assign uid
    passwordFilesLocation = "/var/lib/nixos";
  };
}
