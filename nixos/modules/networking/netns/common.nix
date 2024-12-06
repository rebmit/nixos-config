{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  allNetns = config.networking.netns;
  nonDefaultNetns = filterAttrs (name: _cfg: name != "default") allNetns;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          options = {
            netnsPath = mkOption {
              type = types.str;
              default = if name == "default" then "/proc/1/ns/net" else "/run/netns/${name}";
              readOnly = true;
              description = ''
                Path to the network namespace.
              '';
            };
            mntnsPath = mkOption {
              type = types.str;
              default = if name == "default" then "/proc/1/ns/mnt" else "/run/netns-${name}/mntns/${name}";
              readOnly = true;
              description = ''
                Path to the auxiliary mount namespace.
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
            serviceConfig = mkOption {
              type = types.attrs;
              default =
                if name == "default" then
                  { }
                else
                  {
                    NetworkNamespacePath = config.netnsPath;
                    BindReadOnlyPaths = optionals config.enableDNSIsolation [
                      "/etc/netns/${name}/resolv.conf:/etc/resolv.conf:norbind"
                      "/etc/netns/${name}/nsswitch.conf:/etc/nsswitch.conf:norbind"
                      "/run/netns-${name}/nscd:/run/nscd:norbind"
                    ];
                  };
              readOnly = true;
              description = ''
                Systemd service configuration for entering the network namespace.
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
    networking.netns.default = { };

    systemd.services = listToAttrs (
      mapAttrsToList (
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
      ) nonDefaultNetns
      ++ mapAttrsToList (
        name: cfg:
        let
          inherit (cfg) mntnsPath enableDNSIsolation;
        in
        nameValuePair "netns-${name}-mntns" {
          path = with pkgs; [
            coreutils
            util-linux
          ];
          script = ''
            touch ${mntnsPath} || echo "${mntnsPath} already exists"
            unshare --mount=${mntnsPath} --propagation slave true
            ${optionalString enableDNSIsolation ''
              nsenter --mount=${mntnsPath} mount --bind --read-only /etc/netns/${name}/resolv.conf /etc/resolv.conf
              nsenter --mount=${mntnsPath} mount --bind --read-only /etc/netns/${name}/nsswitch.conf /etc/nsswitch.conf
              nsenter --mount=${mntnsPath} mount --bind --read-only /run/netns-${name}/nscd /run/nscd
            ''}
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            RuntimeDirectory = "netns-${name}/mntns";
          };
          after =
            [
              "netns-${name}.service"
              "network.target"
            ]
            ++ optionals enableDNSIsolation [
              "netns-${name}-nscd.service"
            ];
          partOf = [ "netns-${name}.service" ];
          wantedBy = [
            "multi-user.target"
            "netns-${name}.service"
          ];
        }
      ) nonDefaultNetns
    );

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
