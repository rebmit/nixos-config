{ ... }:
{
  virtualisation.oci-containers.backend = "podman";

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "-af" ];
    };
    defaultNetwork.settings.dns_enabled = false;
    dockerCompat = true;
    dockerSocket.enable = true;
  };
}
