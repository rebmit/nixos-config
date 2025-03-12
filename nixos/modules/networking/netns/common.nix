{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types isList isBool;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) mapAttrs' nameValuePair mapAttrsToList;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) concatLists;
  inherit (lib.trivial) boolToString;
in
{
  options.networking.netns = mkOption {
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
              default = { };
              description = ''
                Systemd service configuration for entering the network namespace.
              '';
            };
            build = mkOption {
              type = types.submodule {
                freeformType = (pkgs.formats.json { }).type;
              };
              default = { };
              description = ''
                Attribute set of derivations used to set up the network namespace.
              '';
            };
          };

          config = mkIf config.enable {
            config = {
              serviceConfig = {
                NetworkNamespacePath = config.netnsPath;
              };
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
      nameValuePair "netns-${name}" (
        mkIf cfg.enable {
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
      )
    ) config.networking.netns;

    environment.systemPackages =
      mapAttrsToList
        (
          name: cfg:
          let
            toOption = x: if isBool x then boolToString x else toString x;
            attrsToProperties =
              as:
              concatStringsSep " " (
                concatLists (
                  mapAttrsToList (
                    name: value:
                    map (x: "--property=\"${name}=${toOption x}\"") (if isList value then value else [ value ])
                  ) as
                )
              );
          in
          mkIf cfg.enable (
            pkgs.writeShellApplication {
              name = "netns-run-${name}";
              text = ''
                systemd-run --pipe --pty \
                  --setenv=PATH \
                  --property="User=$USER" \
                  ${attrsToProperties (cfg.config.serviceConfig or { })} \
                  --same-dir \
                  --wait "$@"
              '';
            }
          )
        )
        (
          config.networking.netns
          // {
            init = {
              enable = true;
              config = { };
            };
          }
        );
  };
}
