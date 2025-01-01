{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports =
    suites.server
    ++ (with profiles; [
      services.caddy
      services.knot.secondary
      services.mail.dovecot
      services.mail.postfix
      services.mail.rspamd
      services.prometheus.node-exporter
      services.prometheus.ping-exporter
      services.well-known
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
