{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkDefault mkIf;
  inherit (lib.attrsets)
    mapAttrs
    mapAttrs'
    nameValuePair
    mapAttrsToList
    ;
  inherit (lib.strings) hasPrefix concatStrings optionalString;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            sysctl = mkOption {
              inherit (options.boot.kernel.sysctl) type;
              default = { };
              apply =
                sysctl:
                mapAttrs (
                  name: value:
                  if hasPrefix "net." name then
                    value
                  else
                    throw "Invalid sysctl key '${name}': must start with 'net.'"
                ) sysctl;
              description = ''
                Per-network namespace runtime parameters of the Linux kernel,
                configurable via {manpage}`sysctl(8)`.
              '';
            };
          };

          config = mkIf config.enable {
            sysctl = {
              "net.ipv6.conf.all.forwarding" = mkDefault 0;
              "net.ipv4.conf.all.forwarding" = mkDefault 0;
              "net.ipv6.conf.default.forwarding" = mkDefault 0;
              "net.ipv4.conf.default.forwarding" = mkDefault 0;
              "net.ipv4.ping_group_range" = mkDefault "0 2147483647";
            };

            config = {
              after = [ "netns-${name}-sysctl.service" ];
              wants = [ "netns-${name}-sysctl.service" ];
            };
          };
        }
      )
    );
  };

  config = {
    systemd.services = mapAttrs' (
      name: cfg:
      nameValuePair "netns-${name}-sysctl" (
        mkIf cfg.enable {
          path = with pkgs; [ procps ];
          script = concatStrings (
            mapAttrsToList (
              n: v: optionalString (v != null) "sysctl -w \"${n}=${if v == false then "0" else toString v}\"\n"
            ) cfg.sysctl
          );
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            NetworkNamespacePath = cfg.netnsPath;
          };
          after = [
            "netns-${name}.service"
            "systemd-modules-load.service"
          ];
          partOf = [ "netns-${name}.service" ];
          wantedBy = [
            "netns-${name}.service"
            "multi-user.target"
          ];
        }
      )
    ) config.networking.netns;
  };
}
