# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/profiles/services/postgresql/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  newPostgres = config.specialisation.target-state-version.configuration.services.postgresql.package;
  upgradePGCluster = pkgs.writeShellApplication {
    name = "upgrade-pg-cluster";
    runtimeInputs = with pkgs; [
      config.systemd.package
      postgresql
    ];
    text = ''
      systemctl stop postgresql

      export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
      export NEWBIN="${newPostgres}/bin"

      export OLDDATA="${config.services.postgresql.dataDir}"
      export OLDBIN="${config.services.postgresql.package}/bin"

      if [ "$OLDDATA" = "$NEWDATA" ]; then
        echo "the old and new data directories are same, exiting..."
        exit 1
      fi

      install -d -m 0700 -o postgres -g postgres "$NEWDATA"
      cd "$NEWDATA"
      sudo --user=postgres $NEWBIN/initdb --pgdata="$NEWDATA"

      sudo --user=postgres $NEWBIN/pg_upgrade \
        --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
        --old-bindir $OLDBIN --new-bindir $NEWBIN \
        "$@"
    '';
  };
in
{
  services.postgresql.enable = true;

  services.postgresqlBackup = {
    enable = true;
    location = "/var/lib/backup/postgresql";
    compression = "zstd";
    backupAll = true;
  };

  services.restic.backups.b2.paths = [ config.services.postgresqlBackup.location ];

  systemd.services."restic-backups-b2" = {
    requires = [ "postgresqlBackup.service" ];
    after = [ "postgresqlBackup.service" ];
  };

  environment.systemPackages = lib.mkIf config.system.pendingStateVersionUpgrade [ upgradePGCluster ];
}
