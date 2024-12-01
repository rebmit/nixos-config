# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy = {
    services = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            overrideStrategy = mkOption {
              type = types.str;
              default = "asDropinIfExists";
            };
          };
        }
      );
      default = { };
      description = ''
        Services that need to run inside the enthalpy network namespace.
      '';
    };
    users = mkOption {
      type = types.attrsOf (types.submodule { });
      default = { };
      description = ''
        Users utilizing the enthalpy network namespace.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services = mapAttrs (_name: value: {
      inherit (value) overrideStrategy;
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${cfg.netns}";
        BindReadOnlyPaths = "/etc/netns/${cfg.netns}/resolv.conf:/etc/resolv.conf:norbind";
      };
      after = [ "enthalpy.service" ];
      requires = [ "enthalpy.service" ];
    }) cfg.services;

    services.enthalpy.services = mapAttrs' (
      name: _value:
      nameValuePair "user@${toString config.users.users.${name}.uid}" {
        overrideStrategy = "asDropin";
      }
    ) cfg.users;
  };
}
