{
  dns,
  lib,
  config,
  ...
}:
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
    CAA
    ;
  A = suwako-vie0.endpoints_v4;
  AAAA = suwako-vie0.endpoints_v6;
  HTTPS = lib.singleton (
    {
      svcPriority = 1;
      targetName = ".";
      alpn = [
        "h3"
        "h2"
      ];
    }
    // (lib.optionalAttrs (suwako-vie0.endpoints_v4 != [ ])) {
      ipv4hint = suwako-vie0.endpoints_v4;
    }
    // (lib.optionalAttrs (suwako-vie0.endpoints_v6 != [ ])) {
      ipv6hint = suwako-vie0.endpoints_v6;
    }
  );
  SRV = [
    {
      service = "imaps";
      proto = "tcp";
      port = config.ports.imap-tls;
      target = "suwako-vie1.rebmit.link.";
    }
    {
      service = "submissions";
      proto = "tcp";
      port = config.ports.smtp-tls;
      target = "suwako-vie1.rebmit.link.";
    }
  ];
  MX = with mx; [ (mx 10 "suwako-vie1.rebmit.link.") ];
  TXT = [ (with spf; soft [ "mx" ]) ];
  subdomains = {
    chat.CNAME = [ "suwako-vie0.rebmit.link." ];
    git.CNAME = [ "suwako-vie0.rebmit.link." ];
    idp.CNAME = [ "suwako-vie0.rebmit.link." ];
    net.CNAME = [ "suwako-vie0.rebmit.link." ];
    prom.CNAME = [ "kanako-ham0.rebmit.link." ];
    push.CNAME = [ "kanako-ham0.rebmit.link." ];
    rss.CNAME = [ "suwako-vie0.rebmit.link." ];
    vault.CNAME = [ "kanako-ham0.rebmit.link." ];
  };
}
