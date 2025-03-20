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
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.strings) concatMapStringsSep;
  inherit (lib.meta) getExe;

  inboundOptions =
    { ... }:
    {
      options = {
        netnsPath = mkOption {
          type = types.str;
          description = ''
            Path to the inbound network namespace.
          '';
        };
        listenAddress = mkOption {
          type = types.str;
          default = "[::1]";
          description = ''
            Address for reciving connections.
          '';
        };
        listenPort = mkOption {
          type = types.int;
          description = ''
            Port number for incoming connections.
          '';
        };
      };
    };
in
{
  options = rec {
    services.proxy = {
      enable = mkEnableOption "mixed proxy for other network namespaces";
      inbounds = mkOption {
        type = types.listOf (types.submodule inboundOptions);
        default = [ ];
        description = ''
          List of inbound configurations for the proxy.
        '';
      };
    };

    networking.netns = mkOption {
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options.services.proxy = services.proxy;
          }
        )
      );
    };
  };

  config = {
    systemd.services =
      mapAttrs'
        (
          name: cfg:
          nameValuePair "netns-${name}-proxy" (
            mkIf (cfg.enable && cfg.services.proxy.enable) (mkMerge [
              cfg.config
              {
                serviceConfig = mylib.misc.serviceHardened // {
                  Type = "simple";
                  Restart = "on-failure";
                  RestartSec = 5;
                  DynamicUser = true;
                  ExecStart = "${getExe pkgs.gost} ${
                    concatMapStringsSep " " (
                      inbound:
                      ''-L "auto://${inbound.listenAddress}:${toString inbound.listenPort}?netns=${inbound.netnsPath}"''
                    ) cfg.services.proxy.inbounds
                  }";
                  ProtectProc = "default";
                  RestrictNamespaces = "net";
                  AmbientCapabilities = [
                    "CAP_SYS_ADMIN"
                    "CAP_SYS_PTRACE"
                  ];
                  CapabilityBoundingSet = [
                    "CAP_SYS_ADMIN"
                    "CAP_SYS_PTRACE"
                  ];
                  SystemCallFilter = [ "@system-service" ];
                };
              }
            ])
          )
        )
        (
          config.networking.netns
          // {
            init = {
              enable = true;
              config = {
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                wantedBy = [ "multi-user.target" ];
              };
              services = {
                inherit (config.services) proxy;
              };
            };
          }
        );
  };
}
