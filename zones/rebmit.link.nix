{ dns, lib, ... }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common) hosts;
  publicHosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) hosts;
  enthalpyHosts = lib.filterAttrs (_name: value: value.enthalpy_node_address != null) hosts;
in
dns.lib.toString "rebmit.link" {
  inherit (common)
    TTL
    SOA
    NS
    DKIM
    DMARC
    ;
  MX = with mx; [ (mx 10 "suwako-vie0.rebmit.link.") ];
  TXT = [ (with spf; soft [ "mx" ]) ];
  subdomains =
    lib.recursiveUpdate
      (lib.listToAttrs (
        lib.mapAttrsToList (
          name: value:
          lib.nameValuePair name {
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
          }
        ) publicHosts
        ++ lib.mapAttrsToList (
          name: value:
          lib.nameValuePair "${name}.enta" {
            AAAA = [ value.enthalpy_node_address ];
          }
        ) enthalpyHosts
      ))
      {
        "suwako-vie0".DMARC = [
          {
            p = "reject";
            sp = "reject";
            pct = 100;
            adkim = "relaxed";
            aspf = "strict";
            fo = [ "1" ];
            ri = 604800;
          }
        ];
      };
}
