{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.services.nscd = {
            enable = mkEnableOption "nscd" // {
              default = true;
            };
          };

          config = mkIf config.enable {
            config = {
              serviceConfig = {
                BindPaths = mkIf config.services.nscd.enable [
                  "${config.runtimeDirectory}/nscd:/run/nscd:rbind"
                ];
                InaccessiblePaths = mkIf (!config.services.nscd.enable) [ "/run/nscd" ];
              };
            };
          };
        }
      )
    );
  };

  config = mkMerge [
    {
      systemd.tmpfiles.settings."20-nscd" = {
        "/run/nscd".d = {
          mode = "0755";
          user = config.services.nscd.user;
          group = config.services.nscd.group;
        };
      };

      systemd.services.nscd.serviceConfig = mkIf config.services.nscd.enable {
        RuntimeDirectory = "nscd";
        RuntimeDirectoryPreserve = true;
      };
    }
    {
      systemd.tmpfiles.settings."20-nscd" = mapAttrs' (
        _name: cfg:
        nameValuePair "${cfg.runtimeDirectory}/nscd" (
          mkIf (cfg.enable && cfg.services.nscd.enable) { d = { }; }
        )
      ) config.networking.netns;

      systemd.services = mapAttrs' (
        name: cfg:
        nameValuePair "netns-${name}-nscd" (
          mkIf (cfg.enable && cfg.services.nscd.enable) (mkMerge [
            cfg.config
            {
              serviceConfig = mylib.misc.serviceHardened // {
                Type = "notify";
                Restart = "on-failure";
                RestartSec = 5;
                DynamicUser = true;
                RuntimeDirectory = "netns-${name}/nscd";
                RuntimeDirectoryPreserve = true;
                ExecStart = "${pkgs.nsncd}/bin/nsncd";
              };
              environment = {
                LD_LIBRARY_PATH = config.system.nssModules.path;
                NSNCD_SOCKET_PATH = "${cfg.runtimeDirectory}/nscd/socket";
              };
            }
          ])
        )
      ) config.networking.netns;
    }
  ];
}
