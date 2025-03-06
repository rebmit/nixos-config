{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
in
{
  options.networking.netns-ng = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            enable = mkEnableOption "the network namespace" // {
              default = true;
            };
            netnsPath = mkOption {
              type = types.str;
              default = "/run/netns/${name}";
              readOnly = true;
              description = ''
                Path to the network namespace, see {manpage}`ip-netns(8)`.
              '';
            };
            config = mkOption {
              type = types.submodule {
                freeformType = (pkgs.formats.json { }).type;
              };
              internal = true;
              default = { };
              description = ''
                Systemd service configuration for entering the network namespace.
              '';
            };
            build = mkOption {
              inherit (options.system.build) type;
              default = { };
              description = ''
                Attribute set of derivations used to set up the network namespace.
              '';
            };
          };

          config = mkIf config.enable {
            config = {
              serviceConfig.NetworkNamespacePath = config.netnsPath;
              after = [ "netns-${name}.service" ];
              partOf = [ "netns-${name}.service" ];
              wantedBy = [
                "netns-${name}.service"
                "multi-user.target"
              ];
            };
          };
        }
      )
    );
    default = { };
    description = ''
      Named network namespace configuration.
    '';
  };

  config = {
    systemd.services = mapAttrs' (
      name: cfg:
      nameValuePair "netns-${name}" {
        inherit (cfg) enable;
        path = with pkgs; [ iproute2 ];
        script = ''
          ip netns add ${name}
          ip -n ${name} link set lo up
        '';
        preStop = ''
          ip netns del ${name}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        restartIfChanged = false;
        after = [ "network-pre.target" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) config.networking.netns-ng;

    # TODO: remove test netns
    networking.netns-ng.test = {
      services.bird = {
        enable = true;
        config = ''
          router id 1;
          protocol device {
            scan time 5;
          }
        '';
      };
    };
  };
}
