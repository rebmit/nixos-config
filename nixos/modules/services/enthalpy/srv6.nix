# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
with lib;
let
  inherit (mylib.network) cidr;
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy.srv6 = {
    enable = mkEnableOption "segment routing over IPv6";
    prefix = mkOption {
      type = types.str;
      default = cidr.subnet 4 6 cfg.prefix;
      description = ''
        Prefix used for SRv6 actions.
      '';
    };
    actions = mkOption {
      type = types.listOf types.str;
      default =
        [
          "${cidr.host 1 cfg.srv6.prefix} encap seg6local action End.DT6 table main  dev enthalpy table localsid"
        ]
        ++ optionals cfg.nat64.enable [
          "${cidr.host 2 cfg.srv6.prefix} encap seg6local action End.DT6 table nat64 dev enthalpy table localsid"
        ];
      description = ''
        List of SRv6 actions configured in the default network namespace.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.srv6.enable) {
    systemd.network.config = {
      networkConfig = {
        IPv6Forwarding = true;
        ManageForeignRoutes = false;
      };
    };

    systemd.network.networks."50-enthalpy" = {
      matchConfig.Name = "enthalpy";
      routes = singleton {
        Destination = "::/0";
        Type = "blackhole";
        Table = config.networking.routingTables.localsid;
      };
      routingPolicyRules = singleton {
        Priority = config.networking.routingPolicyPriorities.localsid;
        Family = "ipv6";
        Table = config.networking.routingTables.localsid;
        From = cfg.network;
        To = cfg.srv6.prefix;
      };
      linkConfig.RequiredForOnline = false;
    };

    services.enthalpy.exit = {
      enable = true;
      prefix = singleton {
        type = "static";
        destination = cfg.srv6.prefix;
        source = cfg.network;
      };
    };

    systemd.services.enthalpy-srv6 = {
      path = with pkgs; [
        iproute2
      ];
      script = concatMapStringsSep "\n" (p: "ip -6 route add ${p}") cfg.srv6.actions;
      preStop = concatMapStringsSep "\n" (p: "ip -6 route del ${p}") cfg.srv6.actions;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [
        "netns-enthalpy.service"
        "enthalpy-exit.service"
      ];
      partOf = [
        "netns-enthalpy.service"
        "enthalpy-exit.service"
      ];
      wantedBy = [
        "multi-user.target"
        "netns-enthalpy.service"
      ];
    };
  };
}
