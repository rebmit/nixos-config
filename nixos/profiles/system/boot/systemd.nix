{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.meta) getExe;
in
{
  environment.etc."machine-id" = {
    source = "/var/lib/nixos/systemd/machine-id";
    mode = "direct-symlink";
  };

  systemd.services.systemd-machine-id-commit = {
    unitConfig.ConditionPathIsMountPoint = [
      ""
      "/var/lib/nixos/systemd/machine-id"
    ];
    serviceConfig.ExecStart = [
      ""
      (getExe (
        pkgs.writeShellApplication {
          name = "machine-id-commit";
          runtimeInputs = with pkgs; [
            bash
            coreutils
            util-linux
          ];
          text = ''
            MACHINE_ID=$(/run/current-system/systemd/bin/systemd-id128 machine-id)
            export MACHINE_ID
            unshare --mount --propagation slave bash ${pkgs.writeShellScript "machine-id-commit" ''
              umount /var/lib/nixos/systemd/machine-id
              printf "$MACHINE_ID" > /var/lib/nixos/systemd/machine-id
            ''}
            umount /var/lib/nixos/systemd/machine-id
          '';
        }
      ))
    ];
  };

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
