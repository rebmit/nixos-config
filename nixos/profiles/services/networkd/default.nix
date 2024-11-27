{ ... }:
{
  networking = {
    useNetworkd = true;
    useDHCP = false;
    domain = "rebmit.link";
  };

  systemd.network.enable = true;
}
