{ dns, lib, ... }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common.hosts) suwako-vie0;
in
dns.lib.toString "rebmit.moe" {
  inherit (common)
    TTL
    SOA
    NS
    DKIM
    DMARC
    ;
  A = suwako-vie0.endpoints_v4;
  AAAA = suwako-vie0.endpoints_v6;
  HTTPS = [
    {
      alpn = [
        "h3"
        "h2"
      ];
    }
  ];
  MX = with mx; [ (mx 10 "suwako-vie0.rebmit.link.") ];
  TXT = [ (with spf; soft [ "mx" ]) ];
  subdomains = {
    keycloak.CNAME = [ "suwako-vie0.rebmit.link." ];
    matrix.CNAME = [ "suwako-vie0.rebmit.link." ];
    miniflux.CNAME = [ "suwako-vie0.rebmit.link." ];
    ntfy.CNAME = [ "suwako-vie0.rebmit.link." ];
  };
}
