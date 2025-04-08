{ lib, ... }:
let
  inherit (lib.modules) mkForce;
in
{
  virtualisation.oci-containers.backend = "podman";

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    autoPrune = {
      enable = true;
      flags = [ "-af" ];
    };
    defaultNetwork.settings.dns_enabled = false;
  };

  # TODO: remove this workaround
  system.etc.overlay.mutable = mkForce true;
}
