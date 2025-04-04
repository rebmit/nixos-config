{
  suites,
  profiles,
  mylib,
  ...
}:
{
  imports = [
    suites.server
    profiles.services.caddy
    profiles.services.mail.dovecot
    profiles.services.mail.postfix
    profiles.services.mail.rspamd
  ] ++ (mylib.path.scanPaths ./. "default.nix");

  system.stateVersion = "24.11";
}
