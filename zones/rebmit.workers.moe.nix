{ dns, ... }:
let
  common = import ./common.nix;
in
dns.lib.toString "rebmit.workers.moe" {
  inherit (common)
    TTL
    SOA
    NS
    CAA
    ;
}
