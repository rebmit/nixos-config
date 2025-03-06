{
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
    ProtectHome = lib.mkForce true;
  };
}
