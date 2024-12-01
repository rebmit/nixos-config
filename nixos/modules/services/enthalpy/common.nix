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
        Prefix to be announced for the local node in the enthalpy network.
      '';
    };
    address = mkOption {
      type = types.str;
      default = cidr.host 1 cfg.prefix;
      description = ''
        Address to be added into the enthalpy network as source address.
      '';
    };
    netns = mkOption {
      type = types.str;
      default = "enthalpy";
      description = ''
        Name of the network namespace for enthalpy interfaces.
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
    systemd.network.networks."50-enthalpy" = {
      matchConfig.Name = "enthalpy";
      linkConfig.RequiredForOnline = false;
    };

    systemd.services.enthalpy = {
      path = with pkgs; [
        iproute2
        coreutils
        procps
      ];
      script = ''
        ip netns add ${cfg.netns}
        ip link add enthalpy mtu 1400 address 02:00:00:00:00:01 type veth peer enthalpy mtu 1400 address 02:00:00:00:00:00 netns ${cfg.netns}
        ip -n ${cfg.netns} link set lo up
        ip -n ${cfg.netns} link set enthalpy up
        ip -n ${cfg.netns} addr add ${cfg.address}/128 dev enthalpy
        ip netns exec ${cfg.netns} sysctl -w net.ipv6.conf.default.forwarding=1
        ip netns exec ${cfg.netns} sysctl -w net.ipv6.conf.all.forwarding=1
        ip netns exec ${cfg.netns} sysctl -w net.ipv4.conf.default.forwarding=0
        ip netns exec ${cfg.netns} sysctl -w net.ipv4.conf.all.forwarding=0
      '';
      preStop = ''
        ip netns del ${cfg.netns}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wants = [ "network.target" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    environment.etc."netns/enthalpy/resolv.conf".text = lib.mkDefault ''
      nameserver 2606:4700:4700::1111
    '';
  };
}
