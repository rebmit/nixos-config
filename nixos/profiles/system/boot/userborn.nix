{ ... }:
{
  services.userborn = {
    enable = true;
    passwordFilesLocation = "/var/lib/nixos/userborn";
  };

  boot.initrd.systemd.tmpfiles.settings.rebmit = {
    "/sysroot/var/lib/nixos/userborn".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };
}
