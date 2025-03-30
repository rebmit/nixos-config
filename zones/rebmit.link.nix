{ dns, lib, ... }:
with dns.lib.combinators;
let
  common = import ./common.nix;
  inherit (common) hosts;
  publicHosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) hosts;
in
dns.lib.toString "rebmit.link" {
  inherit (common)
    TTL
    SOA
    NS
    DKIM
    DMARC
    CAA
    ;
  MX = with mx; [ (mx 10 "suwako-vie1.rebmit.link.") ];
  TXT = [ (with spf; soft [ "mx" ]) ];
  subdomains =
    lib.recursiveUpdate
      (lib.listToAttrs (
        lib.mapAttrsToList (
          name: value:
          lib.nameValuePair name {
            A = value.endpoints_v4;
            AAAA = value.endpoints_v6;
            HTTPS = lib.singleton (
              {
                svcPriority = 1;
                targetName = ".";
                alpn = [
                  "h3"
                  "h2"
                ];
              }
              // (lib.optionalAttrs (value.endpoints_v4 != [ ])) {
                ipv4hint = value.endpoints_v4;
              }
              // (lib.optionalAttrs (value.endpoints_v6 != [ ])) {
                ipv6hint = value.endpoints_v6;
              }
            );
          }
        ) publicHosts
      ))
      {
        "suwako-vie1".DMARC = [
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
