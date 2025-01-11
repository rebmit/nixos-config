{ lib, ... }:
{
  system.etc.overlay.enable = lib.mkDefault true;

  services.userborn = {
    enable = lib.mkDefault true;
    passwordFilesLocation = lib.mkDefault "/var/lib/nixos";
  };
}
