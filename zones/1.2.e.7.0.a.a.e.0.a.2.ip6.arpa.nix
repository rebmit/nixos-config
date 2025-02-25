{
  dns,
  lib,
  ...
}:
with dns.lib.combinators;
let
  common = import ./common.nix;
in
dns.lib.toString "1.2.e.7.0.a.a.e.0.a.2.ip6.arpa" {
  inherit (common)
    TTL
    SOA
    NS
    ;
}
