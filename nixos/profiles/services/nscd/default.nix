{
  config,
  lib,
  mylib,
  ...
}:
{
  services.nscd = {
    enable = true;
    enableNsncd = true;
  };

  systemd.services.nscd.serviceConfig = mylib.misc.serviceHardened // {
    RuntimeDirectory = lib.mkForce "";
    ProtectHome = lib.mkForce true;
  };

  systemd.tmpfiles.settings."20-nscd" = {
    "/run/nscd".d = {
      mode = "0755";
      user = config.services.nscd.user;
      group = config.services.nscd.group;
    };
  };
}
