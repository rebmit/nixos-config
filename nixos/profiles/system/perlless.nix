{ config, lib, ... }:
{
  system.etc.overlay.enable = lib.mkIf (!config.boot.isContainer) true;

  services.userborn = {
    enable = true;
    passwordFilesLocation = "/var/lib/nixos";
  };
}
