{ ... }:
{
  environment.etc."machine-id" = {
    source = "/var/lib/nixos/systemd/machine-id";
    mode = "direct-symlink";
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

  boot.initrd.systemd.tmpfiles.settings.rebmit = {
    "/sysroot/var/lib/nixos/systemd".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };
}
