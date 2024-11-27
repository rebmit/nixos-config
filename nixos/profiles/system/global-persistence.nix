{ ... }:
{
  environment.globalPersistence = {
    directories = [
      "/var/db"
      "/var/lib"
      "/var/log"
      "/var/tmp"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
}
