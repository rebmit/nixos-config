{ config, ... }:
{
  services.forgejo = {
    enable = true;
    lfs.enable = true;
    user = "git";
    group = "git";
    database = {
      type = "postgres";
      user = "git";
      name = "git";
    };
    dump.enable = false;
    settings = {
      DEFAULT = {
        APP_NAME = "rebmit's forge";
      };
      server = {
        DOMAIN = "git.rebmit.moe";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = config.networking.ports.forgejo;
        ROOT_URL = "https://git.rebmit.moe";
        SSH_PORT = config.networking.ports.ssh;
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      session = {
        COOKIE_SECURE = true;
      };
      oauth2_client = {
        ENABLE_AUTO_REGISTRATION = true;
        USERNAME = "userid";
      };
    };
  };

  users.users.git = {
    home = config.services.forgejo.stateDir;
    useDefaultShell = true;
    group = "git";
    isSystemUser = true;
  };

  users.groups.git = { };

  services.caddy.virtualHosts."git.rebmit.moe" = {
    extraConfig = with config.services.forgejo.settings.server; ''
      reverse_proxy ${HTTP_ADDR}:${toString HTTP_PORT}
    '';
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = config.services.forgejo.stateDir;
      mode = "-";
      user = "-";
      group = "-";
    }
  ];

  services.restic.backups.b2.paths = [
    "/persist${config.services.forgejo.stateDir}"
  ];
}
