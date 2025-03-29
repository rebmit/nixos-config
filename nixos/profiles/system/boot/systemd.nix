{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
in
{
  environment.etc."machine-id" = {
    source = "/var/lib/nixos/systemd/machine-id";
    mode = "direct-symlink";
  };

  systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

  boot.initrd.systemd.tmpfiles.settings.rebmit = mkIf config.boot.initrd.systemd.enable {
    "/sysroot/var/lib/nixos/systemd".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
  };

  system.activationScripts.tmpfiles = mkIf (!config.boot.initrd.systemd.enable) {
    text = ''
      mkdir -p /var/lib/nixos/systemd
    '';
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/systemd" ];
}
