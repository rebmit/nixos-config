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
          files = [
            {
              file = config.sops.age.keyFile;
              inInitrd = true;
              mode = "0600";
              user = "root";
              group = "root";
            }
            {
              file = "/etc/machine-id";
              inInitrd = true;
              how = "symlink";
              mode = "-";
              user = "root";
              group = "root";
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
      "${hmCfg.home.homeDirectory}/.cache".d = {
        user = name;
        group = config.users.users.${name}.group;
        mode = "0755";
      };
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
