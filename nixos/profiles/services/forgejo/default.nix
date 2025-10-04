{ config, pkgs, ... }:
let
  cfg = config.services.forgejo;
in
{
  services.forgejo = {
    enable = true;
    lfs.enable = true;
    package = pkgs.forgejo;
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
        HTTP_PORT = config.ports.forgejo;
        ROOT_URL = "https://git.rebmit.moe";
        SSH_PORT = config.ports.ssh;
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
      session = {
        COOKIE_SECURE = true;
      };
      oauth2_client = {
        ENABLE_AUTO_REGISTRATION = true;
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
    extraConfig = ''
      redir /user/login /user/oauth2/idp.rebmit.moe 307
      handle_path /robots.txt {
        respond "User-agent: *
      Disallow: /" 200
      }
      reverse_proxy ${cfg.settings.server.HTTP_ADDR}:${toString cfg.settings.server.HTTP_PORT}
    '';
  };

  preservation.directories = [ config.services.forgejo.stateDir ];
}
