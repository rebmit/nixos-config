{
  dns,
  lib,
  mylib,
  ...
}:
with dns.lib.combinators;
let
  inherit (mylib.network) cidr;

  ipv6Normalize =
    ipv6:
    let
      parsed = lib.splitString ":" (lib.network.ipv6.fromString ipv6).address;
      pad = hextet: lib.concatStrings (lib.replicate (4 - lib.stringLength hextet) "0") + hextet;
      normalize = hextet: lib.stringToCharacters (pad hextet);
    in
    lib.flatten (map normalize parsed);

  ipv6ToPtr =
    ipv6:
    let
      parsed = lib.reverseList (ipv6Normalize ipv6);
      ptr = lib.concatStringsSep "." (lib.take 21 parsed);
    in
    ptr;

  common = import ./common.nix;
  inherit (common) hosts;
  enthalpyHosts = lib.filterAttrs (_name: value: value.enthalpy_node_prefix != null) hosts;
in
dns.lib.toString "1.2.e.7.0.a.a.e.0.a.2.ip6.arpa" {
  inherit (common)
    TTL
    SOA
    NS
    ;

  subdomains = lib.listToAttrs (
    lib.mapAttrsToList (
      name: value:
      lib.nameValuePair "${ipv6ToPtr (cidr.host 1 value.enthalpy_node_prefix)}" {
        PTR = [ "${name}.enta.rebmit.link." ];
      }
    ) enthalpyHosts
    ++ lib.singleton (
      lib.nameValuePair "${ipv6ToPtr "2a0e:aa07:e210:100::1"}" {
        PTR = [ "reisen.any.rebmit.link." ];
      }
    )
  );
}
