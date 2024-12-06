{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
with lib;
let
  allNetns = config.networking.netns;
  nonDefaultNetns = filterAttrs (_name: cfg: cfg.netns != "default") allNetns;

  mkService =
    cfg:
    let
      inherit (cfg)
        netns
        interface
        address
        ;
      enableIPv4Forwarding = if cfg.enableIPv4Forwarding then "1" else "0";
      enableIPv6Forwarding = if cfg.enableIPv6Forwarding then "1" else "0";
    in
    {
      path = with pkgs; [
        coreutils
        iproute2
        procps
      ];
      script = ''
        ip netns add ${netns}
        ip -n ${netns} link add ${interface} type dummy
        ip -n ${netns} link set lo up
        ip -n ${netns} link set ${interface} up
        ip netns exec ${netns} sysctl -w net.ipv4.conf.default.forwarding=${enableIPv4Forwarding}
        ip netns exec ${netns} sysctl -w net.ipv4.conf.all.forwarding=${enableIPv4Forwarding}
        ip netns exec ${netns} sysctl -w net.ipv6.conf.default.forwarding=${enableIPv6Forwarding}
        ip netns exec ${netns} sysctl -w net.ipv6.conf.all.forwarding=${enableIPv6Forwarding}
        ${concatMapStringsSep "\n" (addr: "ip -n ${netns} addr add ${addr} dev ${interface}") address}
      '';
      preStop = ''
        ip netns del ${netns}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };

  # https://flokli.de/posts/2022-11-18-nsncd
  mkNscdService =
    cfg:
    let
      inherit (cfg) netns netnsPath;
    in
    {
      serviceConfig = mylib.misc.serviceHardened // {
        NetworkNamespacePath = netnsPath;
        BindReadOnlyPaths = [
          "/etc/netns/${netns}/resolv.conf:/etc/resolv.conf:norbind"
          "/etc/netns/${netns}/nsswitch.conf:/etc/nsswitch.conf:norbind"
        ];
        BindPaths = [ "/run/netns-${netns}/nscd:/run/nscd:norbind" ];
        Type = "notify";
        Restart = "always";
        RestartSec = 5;
        DynamicUser = true;
        RuntimeDirectory = "netns-${netns}/nscd";
        ExecStart = "${pkgs.nsncd}/bin/nsncd";
      };
      environment.LD_LIBRARY_PATH = config.system.nssModules.path;
      after = [
        "netns-${netns}.service"
        "network.target"
      ];
      partOf = [ "netns-${netns}.service" ];
      wantedBy = [
        "multi-user.target"
        "netns-${netns}.service"
      ];
    };

  mkAuxMntnsService =
    cfg:
    let
      inherit (cfg)
        netns
        mntnsPath
        ;
    in
    {
      path = with pkgs; [
        coreutils
        util-linux
      ];
      script = ''
        touch ${mntnsPath} || echo "${mntnsPath} already exists"
        unshare --mount=${mntnsPath} --propagation slave mount --bind --read-only /etc/netns/${netns}/resolv.conf /etc/resolv.conf
        nsenter --mount=${mntnsPath} mount --bind --read-only /etc/netns/${netns}/nsswitch.conf /etc/nsswitch.conf
        nsenter --mount=${mntnsPath} mount --bind --read-only /run/netns-${netns}/nscd /run/nscd
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [
        "netns-${netns}.service"
        "netns-${netns}-nscd.service"
        "network.target"
      ];
      partOf = [ "netns-${netns}.service" ];
      wantedBy = [
        "multi-user.target"
        "netns-${netns}.service"
      ];
    };

  mkPortForwardService =
    cfg: fp:
    let
      inherit (fp) protocol source target;
      sourceNetns = fp.netns;
      sourceNetnsPath = config.networking.netns.${sourceNetns}.netnsPath;
      targetNetns = cfg.netns;
      targetNetnsConfig = cfg.serviceConfig;
      serviceDeps = map (ns: "netns-${ns}.service") (
        filter (ns: ns != "default") [
          sourceNetns
          targetNetns
        ]
      );
    in
    {
      serviceConfig =
        mylib.misc.serviceHardened
        // targetNetnsConfig
        // {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          ExecStart = "${pkgs.netns-proxy}/bin/netns-proxy ${sourceNetnsPath} ${source} -b ${target} -p ${protocol} -v";
          ProtectProc = false;
          RestrictNamespaces = "net";
          AmbientCapabilities = [
            "CAP_SYS_ADMIN"
            "CAP_SYS_PTRACE"
          ];
          CapabilityBoundingSet = [
            "CAP_SYS_ADMIN"
            "CAP_SYS_PTRACE"
          ];
        };
      after = [
        "network.target"
      ] ++ serviceDeps;
      partOf = serviceDeps;
      wantedBy = [
        "multi-user.target"
      ] ++ serviceDeps;
    };

  mkExtraVethService =
    cfg: ev:
    let
      inherit (ev)
        sourceInterface
        targetInterface
        ;
      sourceNetns = cfg.netns;
      sourceNetnsPath = cfg.netnsPath;
      targetNetns = ev.netns;
      targetNetnsPath = config.networking.netns.${targetNetns}.netnsPath;
      serviceDeps = map (ns: "netns-${ns}.service") (
        filter (ns: ns != "default") [
          sourceNetns
          targetNetns
        ]
      );
      mkSetup =
        netns: _netnsPath: interface:
        if netns == "default" then "ip link set ${interface} up" else "ip -n ${netns} link set ${interface} up";
      mkDrop =
        netns: _netnsPath: interface:
        if netns == "default" then "ip link del ${interface}" else "ip -n ${netns} link del ${interface}";
    in
    {
      path = with pkgs; [
        coreutils
        iproute2
        procps
      ];
      script = ''
        ip link add ${sourceInterface} mtu 1400 address 02:00:00:00:00:01 netns ${sourceNetnsPath} type veth \
          peer ${targetInterface} mtu 1400 address 02:00:00:00:00:00 netns ${targetNetnsPath}
        ${mkSetup sourceNetns sourceNetnsPath sourceInterface}
        ${mkSetup targetNetns targetNetnsPath targetInterface}
      '';
      preStop = ''
        ${mkDrop sourceNetns sourceNetnsPath sourceInterface}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      after = [
        "network.target"
      ] ++ serviceDeps;
      partOf = serviceDeps;
      wantedBy = [
        "multi-user.target"
      ] ++ serviceDeps;
    };

  defaultResolv = pkgs.writeText "netns-default-resolv-conf" ''
    nameserver 2606:4700:4700::1111
    nameserver 2001:4860:4860::8888
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  defaultNsswitch = pkgs.writeText "netns-default-nsswitch-conf" ''
    passwd:    ${concatStringsSep " " config.system.nssDatabases.passwd}
    group:     ${concatStringsSep " " config.system.nssDatabases.group}
    shadow:    ${concatStringsSep " " config.system.nssDatabases.shadow}
    sudoers:   ${concatStringsSep " " config.system.nssDatabases.sudoers}

    hosts:     ${concatStringsSep " " (remove "resolve [!UNAVAIL=return]" config.system.nssDatabases.hosts)}
    networks:  files

    ethers:    files
    services:  ${concatStringsSep " " config.system.nssDatabases.services}
    protocols: files
    rpc:       files
  '';
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        let
          netnsConfig = config;
        in
        {
          options = {
            netns = mkOption {
              type = types.str;
              default = name;
              readOnly = true;
              description = ''
                Name of the network namespace.
              '';
            };
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
              default = if name == "default" then "/proc/1/ns/mnt" else "/run/netns-${name}/mntns";
              readOnly = true;
              description = ''
                Path to the auxiliary mount namespace.
              '';
            };
            serviceConfig = mkOption {
              type = types.attrs;
              default =
                if config.netns == "default" then
                  { }
                else
                  {
                    NetworkNamespacePath = config.netnsPath;
                    BindReadOnlyPaths = [
                      "/etc/netns/${config.netns}/resolv.conf:/etc/resolv.conf:norbind"
                      "/etc/netns/${config.netns}/nsswitch.conf:/etc/nsswitch.conf:norbind"
                      "/run/netns-${config.netns}/nscd:/run/nscd:norbind"
                    ];
                  };
              readOnly = true;
              description = ''
                Systemd service configuration for entering the network namespace.
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
            forwardPorts = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    protocol = mkOption {
                      type = types.enum [
                        "tcp"
                        "udp"
                      ];
                      default = "tcp";
                      description = ''
                        The protocol specifier for port forwarding between network namespaces.
                      '';
                    };
                    netns = mkOption {
                      type = types.str;
                      default = "default";
                      description = ''
                        The network namespace to forward ports from.
                      '';
                    };
                    source = mkOption {
                      type = types.str;
                      description = ''
                        The source endpoint in the specified network namespace to forward.
                      '';
                    };
                    target = mkOption {
                      type = types.str;
                      description = ''
                        The target endpoint in the current network namespace to listen on.
                      '';
                    };
                  };
                }
              );
              default = [ ];
              description = ''
                List of forwarded ports from another network namespace to this
                network namespace.
              '';
            };
            extraVeths = mkOption {
              type = types.listOf (
                types.submodule (
                  { config, ... }:
                  {
                    options = {
                      netns = mkOption {
                        type = types.str;
                        default = "default";
                        description = ''
                          The network namespace to connect to.
                        '';
                      };
                      sourceInterface = mkOption {
                        type = types.str;
                        default = if config.netns == "default" then "host" else config.netns;
                        description = ''
                          The interface name in current network namespace;
                        '';
                      };
                      targetInterface = mkOption {
                        type = types.str;
                        default = if netnsConfig.netns == "default" then "host" else netnsConfig.netns;
                        description = ''
                          The interface name in the other network namespace;
                        '';
                      };
                    };
                  }
                )
              );
              default = [ ];
              description = ''
                Extra veth-pairs to be created for enabling link-scope connectivity
                between inter-network namespaces.
                Note that a veth-pair only needs to be defined on one end.
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
      mapAttrsToList (_name: cfg: nameValuePair "netns-${cfg.netns}" (mkService cfg)) nonDefaultNetns
      ++ mapAttrsToList (
        _name: cfg: nameValuePair "netns-${cfg.netns}-nscd" (mkNscdService cfg)
      ) nonDefaultNetns
      ++ mapAttrsToList (
        _name: cfg: nameValuePair "netns-${cfg.netns}-mntns" (mkAuxMntnsService cfg)
      ) nonDefaultNetns
      ++ flatten (
        mapAttrsToList (
          _name: cfg:
          (imap (
            index: fp:
            nameValuePair "netns-${cfg.netns}-port-forward-${toString index}-${fp.netns}-${fp.protocol}" (
              mkPortForwardService cfg fp
            )
          ) cfg.forwardPorts)
        ) allNetns
      )
      ++ flatten (
        mapAttrsToList (
          _name: cfg:
          (imap (
            index: ev:
            nameValuePair "netns-${cfg.netns}-extra-veth-${toString index}-${ev.netns}" (
              mkExtraVethService cfg ev
            )
          ) cfg.extraVeths)
        ) allNetns
      )
    );

    environment.etc = listToAttrs (
      mapAttrsToList (
        _name: cfg:
        nameValuePair "netns/${cfg.netns}/resolv.conf" {
          source = mkDefault defaultResolv;
        }
      ) nonDefaultNetns
      ++ mapAttrsToList (
        _name: cfg:
        nameValuePair "netns/${cfg.netns}/nsswitch.conf" {
          source = mkDefault defaultNsswitch;
        }
      ) nonDefaultNetns
    );

    environment.systemPackages = mapAttrsToList (
      name: cfg:
      let
        inherit (cfg) netns netnsPath mntnsPath;
      in
      pkgs.writeShellApplication {
        name = "netns-run-${netns}";
        runtimeInputs = with pkgs; [ util-linux ];
        text = ''
          pkexec nsenter -t $$ -e --mount=${mntnsPath} --net=${netnsPath} -S "$(id -u)" -G "$(id -g)" --wdns="$PWD" "$@"
        '';
      }
    ) allNetns;
  };
}
