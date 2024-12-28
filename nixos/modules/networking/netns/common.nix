{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  allNetns = config.networking.netns;
  nonDefaultNetns = filterAttrs (name: _cfg: name != "init") allNetns;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            netnsPath = mkOption {
              type = types.str;
              default = if name == "init" then "/proc/1/ns/net" else "/run/netns/${name}";
              readOnly = true;
              description = ''
                Path to the network namespace.
              '';
            };
            interface = mkOption {
              type = types.str;
              default = name;
              description = ''
                Name of the dummy interface to add the address.
              '';
            };
            address = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = ''
                Address to be added into the network namespace as source address.
              '';
            };
            enableIPv4Forwarding = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to enable IPv4 packet forwarding in the network namespace.
              '';
            };
            enableIPv6Forwarding = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to enable IPv6 packet forwarding in the network namespace.
              '';
            };
          };
        }
      )
    );
    description = ''
      Network namespace configuration.
    '';
  };

  config = {
    networking.netns.init = { };

    systemd.services = mapAttrs' (
      name: cfg:
      let
        inherit (cfg) interface address;
        enableIPv4Forwarding = if cfg.enableIPv4Forwarding then "1" else "0";
        enableIPv6Forwarding = if cfg.enableIPv6Forwarding then "1" else "0";
      in
      nameValuePair "netns-${name}" {
        path = with pkgs; [
          coreutils
          iproute2
          procps
        ];
        script = ''
          ip netns add ${name}
          ip -n ${name} link add ${interface} type dummy
          ip -n ${name} link set lo up
          ip -n ${name} link set ${interface} up
          ip netns exec ${name} sysctl -w net.ipv4.conf.default.forwarding=${enableIPv4Forwarding}
          ip netns exec ${name} sysctl -w net.ipv4.conf.all.forwarding=${enableIPv4Forwarding}
          ip netns exec ${name} sysctl -w net.ipv6.conf.default.forwarding=${enableIPv6Forwarding}
          ip netns exec ${name} sysctl -w net.ipv6.conf.all.forwarding=${enableIPv6Forwarding}
          ip netns exec ${name} sysctl -w net.ipv4.ping_group_range="0 2147483647"
          ${concatMapStringsSep "\n" (addr: "ip -n ${name} addr add ${addr} dev ${interface}") address}
        '';
        preStop = ''
          ip netns del ${name}
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) nonDefaultNetns;

    environment.systemPackages = mkIf (nonDefaultNetns != { }) (
      mapAttrsToList (
        name: cfg:
        let
          inherit (cfg) netnsPath mntnsPath;
        in
        pkgs.writeShellApplication {
          name = "netns-run-${name}";
          runtimeInputs = with pkgs; [ util-linux ];
          text = ''
            pkexec nsenter -t $$ -e --mount=${mntnsPath} --net=${netnsPath} -S "$(id -u)" -G "$(id -g)" --wdns="$PWD" "$@"
          '';
        }
      ) allNetns
    );
  };
}
