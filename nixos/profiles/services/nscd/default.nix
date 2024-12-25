{ lib, mylib, ... }:
{
  services.nscd = {
    enable = true;
    enableNsncd = true;
  };

  systemd.services.nscd.serviceConfig = mylib.misc.serviceHardened // {
    RuntimeDirectoryPreserve = true;
    ProtectHome = lib.mkForce true;
  };
}
