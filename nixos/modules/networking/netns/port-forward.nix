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
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { ... }:
        {
          options.forwardPorts = mkOption {
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
        }
      )
    );
  };

  config = {
    systemd.services = listToAttrs (
      flatten (
        mapAttrsToList (
          name: cfg:
          (imap (
            index: fp:
            let
              inherit (fp)
                protocol
                source
                target
                netns
                ;
              netnsPath = config.networking.netns.${netns}.netnsPath;
              serviceDeps = map (ns: "netns-${ns}.service") (
                filter (ns: ns != "default") [
                  name
                  netns
                ]
              );
            in
            nameValuePair "netns-${name}-port-forward-${toString index}-${netns}-${protocol}" {
              serviceConfig =
                mylib.misc.serviceHardened
                // cfg.serviceConfig
                // {
                  Type = "simple";
                  Restart = "on-failure";
                  RestartSec = 5;
                  DynamicUser = true;
                  User = "${name}-port-forward-${toString index}";
                  ExecStart = "${pkgs.netns-proxy}/bin/netns-proxy ${netnsPath} ${source} -b ${target} -p ${protocol} -v";
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
            }
          ) cfg.forwardPorts)
        ) allNetns
      )
    );
  };
}
