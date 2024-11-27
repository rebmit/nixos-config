{ lib, ... }:
{
  networking = {
    nftables.enable = true;
    firewall.enable = lib.mkDefault false;
  };
}
