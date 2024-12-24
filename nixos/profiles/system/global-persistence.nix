{ config, ... }:
{
  assertions = [
    {
      assertion = config.fileSystems ? "/persist";
      message = ''
        `config.fileSystems."/persist"` must be set.
      '';
    }
  ];

  environment.globalPersistence = {
    enable = true;
    root = "/persist";
    directories = [
      "/var/cache"
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
