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
  options.networking.netns-ng = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            nscd.enable = mkEnableOption "nscd in the network namespace" // {
              default = true;
            };
          };

          config = mkIf config.enable {
            config = {
              serviceConfig = {
                BindReadOnlyPaths = mkIf config.nscd.enable [ "/run/netns-${name}/nscd:/run/nscd:norbind" ];
                InaccessiblePaths = mkIf (!config.nscd.enable) [ "/run/nscd" ];
              };
              after = [ "netns-${name}-nscd.service" ];
              requires = [ "netns-${name}-nscd.service" ];
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
      systemd.services = mapAttrs' (
        name: cfg:
        nameValuePair "netns-${name}-nscd" (
          mkIf (cfg.enable && cfg.nscd.enable) {
            serviceConfig = mylib.misc.serviceHardened // {
              NetworkNamespacePath = cfg.netnsPath;
              BindReadOnlyPaths = [ "/run/netns-${name}/confext/etc:/etc:norbind" ];
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
              NSNCD_SOCKET_PATH = "/run/netns-${name}/nscd/socket";
            };
            after = [
              "netns-${name}.service"
              "netns-${name}-confext.service"
            ];
            requires = [ "netns-${name}-confext.service" ];
            partOf = [ "netns-${name}.service" ];
            wantedBy = [
              "netns-${name}.service"
              "multi-user.target"
            ];
          }
        )
      ) config.networking.netns-ng;
    }
  ];
}
