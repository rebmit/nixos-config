# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/backup/default.nix (MIT License)
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/profiles/services/restic/default.nix (MIT License)
{
  config,
  lib,
  host,
  ...
}:
let
  inherit (lib.lists) singleton;
in
{
  services.restic.backups.b2 = {
    repository = "b2:${host.b2_backup_bucket_name}";
    environmentFile = config.sops.templates.restic-b2-envs.path;
    passwordFile = config.sops.secrets.restic-password.path;
    initialize = true;
    paths = [ "/persist" ];
    extraBackupArgs = [
      "--one-file-system"
      "--exclude-caches"
      "--no-scan"
      "--retry-lock 2h"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "4h";
      FixedRandomDelay = true;
      Persistent = true;
    };
  };

  systemd.services.restic-backups-b2.serviceConfig.Environment = [ "GOGC=20" ];

  sops.secrets.b2-backup-application-key-id = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "restic-backups-b2.service" ];
  };

  sops.secrets.b2-backup-application-key = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "restic-backups-b2.service" ];
  };

  sops.secrets.restic-password = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "restic-backups-b2.service" ];
  };

  sops.templates.restic-b2-envs.content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder.b2-backup-application-key-id}"
    B2_ACCOUNT_KEY="${config.sops.placeholder.b2-backup-application-key}"
  '';

  preservation.preserveAt."/persist".directories = singleton {
    directory = "/var/cache/restic-backups-b2";
    mode = "0755";
    user = "root";
    group = "root";
  };
}
