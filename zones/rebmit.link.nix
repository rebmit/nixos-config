{
  dns,
  lib,
  mylib,
  ...
}:
with dns.lib.combinators;
let
  inherit (mylib.network) cidr;

  common = import ./common.nix;
  inherit (common) hosts;
  publicHosts = lib.filterAttrs (_name: value: value.endpoints != [ ]) hosts;
  enthalpyHosts = lib.filterAttrs (_name: value: value.enthalpy_node_prefix != null) hosts;
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
  MX = with mx; [ (mx 10 "kogasa-nue0.rebmit.link.") ];
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
        ++ lib.mapAttrsToList (
          name: value:
          lib.nameValuePair "${name}.enta" {
            AAAA = [ (cidr.host 1 value.enthalpy_node_prefix) ];
            HTTPS = lib.singleton {
              svcPriority = 1;
              targetName = ".";
              alpn = [
                "h3"
                "h2"
              ];
              ipv6hint = [ (cidr.host 1 value.enthalpy_node_prefix) ];
            };
          }
        ) enthalpyHosts
        ++ lib.singleton (
          lib.nameValuePair "reisen.any" {
            AAAA = [ "2a0e:aa07:e210:100::1" ];
            HTTPS = lib.singleton {
              svcPriority = 1;
              targetName = ".";
              alpn = [
                "h3"
                "h2"
              ];
              ipv6hint = [ "2a0e:aa07:e210:100::1" ];
            };
          }
        )
      ))
      {
        acme = {
          NS = [ "reisen.any.rebmit.link." ];
        };
        "kogasa-nue0".DMARC = [
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
