{ dns, ... }:
let
  common = import ./common.nix;
in
dns.lib.toString "acme.rebmit.link" {
  inherit (common)
    SOA
    CAA
    ;
  TTL = 30;
  NS = [
    "reisen.any.rebmit.link."
    "suwako-vie1.rebmit.link."
  ];
}
