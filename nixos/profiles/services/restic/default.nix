# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/backup/default.nix (MIT License)
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/profiles/services/restic/default.nix (MIT License)
{ config, hostData, ... }:
{
  sops.secrets."b2_backup_application_key_id" = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "restic-backups-b2.service" ];
  };

  sops.secrets."b2_backup_application_key" = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "restic-backups-b2.service" ];
  };

  sops.secrets."restic_password" = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "restic-backups-b2.service" ];
  };

  sops.templates."restic_b2_envs".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder."b2_backup_application_key_id"}"
    B2_ACCOUNT_KEY="${config.sops.placeholder."b2_backup_application_key"}"
  '';

  services.restic.backups.b2 = {
    repository = "b2:${hostData.b2_backup_bucket_name}";
    environmentFile = config.sops.templates."restic_b2_envs".path;
    passwordFile = config.sops.secrets."restic_password".path;
    initialize = true;
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

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/cache/restic-backups-b2";
      mode = "0755";
      user = "root";
      group = "root";
    }
  ];

  services.restic.backups.b2.paths = [
    "/persist/etc/machine-id"
    "/persist${config.sops.age.keyFile}"
    "/persist/var/lib/nixos"
  ];

  systemd.services.restic-backups-b2.serviceConfig.Environment = [ "GOGC=20" ];
}
