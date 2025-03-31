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
      services.knot.primary
      services.mail.dovecot
      services.mail.postfix
      services.mail.rspamd
      services.ntfy
      services.prometheus.server
      services.vaultwarden
    ])
    ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
