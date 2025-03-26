{ ... }:
{
  environment.etc."machine-id" = {
    source = "/var/lib/nixos/systemd/machine-id";
    mode = "direct-symlink";
  };

  systemd.tmpfiles.settings.rebmit = {
    "/var/lib/nixos/systemd".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
