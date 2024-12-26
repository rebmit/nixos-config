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
              directory = "/var/cache";
              inInitrd = true;
            }
            {
              directory = "/var/lib";
              inInitrd = true;
            }
            {
              directory = "/var/log";
              inInitrd = true;
            }
            {
              directory = "/var/tmp";
              inInitrd = true;
            }
          ];
          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
              how = "symlink";
              configureParent = true;
            }
          ];
        };
      }
    );
  };

  # https://github.com/NixOS/nixpkgs/pull/351151#issuecomment-2549025171
  systemd.services.systemd-machine-id-commit = {
    unitConfig.ConditionPathIsMountPoint = [
      ""
      "/persist/etc/machine-id"
    ];
    serviceConfig.ExecStart = [
      ""
      "systemd-machine-id-setup --commit --root /persist"
    ];
  };

  # https://willibutz.github.io/preservation/examples.html
  systemd.tmpfiles.settings.preservation = lib.mkMerge (
    lib.mapAttrsToList (name: hmCfg: {
      "${hmCfg.home.homeDirectory}/.config".d = {
        user = name;
        group = config.users.users.${name}.group;
        mode = "0755";
      };
      "${hmCfg.home.homeDirectory}/.local".d = {
        user = name;
        group = config.users.users.${name}.group;
        mode = "0755";
      };
      "${hmCfg.home.homeDirectory}/.local/share".d = {
        user = name;
        group = config.users.users.${name}.group;
        mode = "0755";
      };
      "${hmCfg.home.homeDirectory}/.local/state".d = {
        user = name;
        group = config.users.users.${name}.group;
        mode = "0755";
      };
    }) (lib.filterAttrs (_: hmCfg: hmCfg.preservation.enable) config.home-manager.users)
  );
}
