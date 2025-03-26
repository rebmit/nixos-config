{ config, lib, ... }:
{
  assertions = [
    {
      assertion = config.fileSystems ? "/persist";
      message = ''
        `config.fileSystems."/persist"` must be set.
      '';
    }
  ];

  # TODO: re-implement preservation with a more proper ordering
  preservation = {
    enable = true;
    preserveAt = lib.mkMerge (
      lib.mapAttrsToList (
        name: hmCfg:
        lib.mapAttrs (_: preserve: {
          users.${name} = {
            home = hmCfg.home.homeDirectory;
            inherit (preserve) directories files;
          };
        }) hmCfg.preservation.preserveAt
      ) (lib.filterAttrs (_: hmCfg: hmCfg.preservation.enable) config.home-manager.users)
      ++ lib.singleton {
        "/persist" = {
          directories = [
            {
              directory = "/var/lib/machines";
              mode = "-";
              user = "-";
              group = "-";
            }
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
              mode = "0755";
              user = "root";
              group = "root";
            }
            {
              directory = "/var/lib/portables";
              mode = "-";
              user = "-";
              group = "-";
            }
            {
              directory = "/var/lib/systemd";
              mode = "-";
              user = "-";
              group = "-";
            }
            {
              directory = "/var/tmp";
              mode = "-";
              user = "-";
              group = "-";
            }
          ];
        };
      }
    );
  };
}
