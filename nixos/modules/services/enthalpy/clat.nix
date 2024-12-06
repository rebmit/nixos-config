# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/mainframe/gravity.nix
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
  interface = config.networking.netns.${cfg.netns}.interface;
in
{
  options.services.enthalpy.clat = {
    enable = mkEnableOption "464XLAT for IPv4 connectivity";
    address = mkOption {
      type = types.str;
      default = cidr.host 2 cfg.prefix;
      description = ''
        IPv6 address used for 464XLAT as the mapped source address.
      '';
    };
    segment = mkOption {
      type = types.listOf types.str;
      description = ''
        SRv6 segments used for NAT64.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.clat.enable) {
    systemd.services.enthalpy-clat = {
      path = with pkgs; [
        iproute2
        tayga
      ];
      preStart = ''
        ip -6 route replace 64:ff9b::/96 from ${cfg.clat.address} encap seg6 mode encap \
          segs ${concatStringsSep "," cfg.clat.segment} dev ${interface} mtu 1280
      '';
      script = ''
        exec tayga --config ${pkgs.writeText "tayga.conf" ''
          tun-device clat
          prefix 64:ff9b::/96
          ipv4-addr 192.0.0.1
          map 192.0.0.2 ${cfg.clat.address}
        ''}
      '';
      postStart = ''
        ip link set clat up
        ip -4 addr add 192.0.0.2/32 dev clat
        ip -6 route add ${cfg.clat.address} dev clat
        ip -4 route add 0.0.0.0/0 dev clat src 192.0.0.2
      '';
      preStop = ''
        ip -6 route del 64:ff9b::/96 from ${cfg.clat.address} encap seg6 mode encap \
          segs ${concatStringsSep "," cfg.clat.segment} dev ${interface} mtu 1280
      '';
      serviceConfig =
        mylib.misc.serviceHardened
        // config.networking.netns.${cfg.netns}.serviceConfig
        // {
          Type = "forking";
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
          AmbientCapabilities = [ "CAP_NET_ADMIN" ];
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          PrivateDevices = false;
        };
      after = [ "netns-${cfg.netns}.service" ];
      partOf = [ "netns-${cfg.netns}.service" ];
      wantedBy = [
        "multi-user.target"
        "netns-${cfg.netns}.service"
      ];
    };
  };
}
