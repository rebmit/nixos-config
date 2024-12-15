{ dns, lib, ... }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  hosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) common.hosts;
in
dns.lib.toString "rebmit.link" {
  inherit (common)
    TTL
    SOA
    NS
    ;
  subdomains = builtins.mapAttrs (_name: value: {
    A = value.endpoints_v4;
    AAAA = value.endpoints_v6;
    HTTPS = [
      {
        alpn = [
          "h3"
          "h2"
        ];
      }
    ];
  }) hosts;
}
