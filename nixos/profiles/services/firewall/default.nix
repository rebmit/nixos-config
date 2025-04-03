{ lib, ... }:
let
  inherit (lib.modules) mkDefault;
in
{
  networking = {
    nftables.enable = true;
    firewall.enable = mkDefault false;
  };
}
