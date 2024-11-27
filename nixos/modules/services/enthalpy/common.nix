# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/882da114b98389121d98d909f115d49d9af6613e/modules/gravity.nix
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
  options.services.enthalpy = {
    enable = mkEnableOption "enthalpy overlay network";
    prefix = mkOption {
      type = types.str;
      description = ''
        Prefix to be announced for the local node.
      '';
    };
    netns = mkOption {
      type = types.str;
      default = "enthalpy";
      description = ''
        Name of the network namespace for interfaces.
      '';
    };
    interface = mkOption {
      type = types.str;
      default = "enthalpy";
      description = ''
        Name of the interface to connect to the network namespace.
      '';
    };
    network = mkOption {
      type = types.str;
      description = ''
        Prefix of the enthalpy network.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.enthalpy = {
      path = with pkgs; [
        iproute2
        coreutils
        procps
      ];
      script = ''
        ip netns add ${cfg.netns}
        ip link add ${cfg.interface} mtu 1400 address 02:00:00:00:00:01 type veth peer enthalpy mtu 1400 address 02:00:00:00:00:00 netns ${cfg.netns}
        ip link set ${cfg.interface} up
        ip -n ${cfg.netns} link set lo up
        ip -n ${cfg.netns} link set enthalpy up
        ip -n ${cfg.netns} addr add ${cidr.host 0 cfg.prefix}/127 dev enthalpy
        ip netns exec ${cfg.netns} sysctl -w net.ipv6.conf.default.forwarding=1
        ip netns exec ${cfg.netns} sysctl -w net.ipv6.conf.all.forwarding=1
      '';
      preStop = ''
        ip link del ${cfg.interface}
        ip netns del ${cfg.netns}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    systemd.network.networks."50-enthalpy" = {
      matchConfig.Name = cfg.interface;
      networkConfig.Address = "${cidr.host 1 cfg.prefix}/127";
      routes = singleton {
        Destination = cfg.network;
        Gateway = "fe80::ff:fe00:0";
      };
    };
  };
}
