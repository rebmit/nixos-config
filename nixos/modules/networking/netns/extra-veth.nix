{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  allNetns = config.networking.netns;
  allExtraVeths = flatten (mapAttrsToList (_name: cfg: cfg.extraVeths) allNetns);
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options.extraVeths = mkOption {
            type = types.listOf (
              types.submodule (
                { config, ... }:
                {
                  options = {
                    sourceNetns = mkOption {
                      type = types.str;
                      default = name;
                      readOnly = true;
                      description = ''
                        The current network namespace.
                      '';
                    };
                    targetNetns = mkOption {
                      type = types.str;
                      description = ''
                        The network namespace to connect to.
                      '';
                    };
                    sourceInterface = mkOption {
                      type = types.str;
                      default = if config.targetNetns == "default" then "host" else config.targetNetns;
                      description = ''
                        The interface name in the current network namespace;
                      '';
                    };
                    targetInterface = mkOption {
                      type = types.str;
                      default = if config.sourceNetns == "default" then "host" else config.sourceNetns;
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
        }
      )
    );
  };

  config = {
    systemd.services = listToAttrs (
      map (
        ev:
        let
          inherit (ev)
            sourceNetns
            targetNetns
            sourceInterface
            targetInterface
            ;
          sourceNetnsPath = config.networking.netns.${sourceNetns}.netnsPath;
          targetNetnsPath = config.networking.netns.${targetNetns}.netnsPath;
          serviceDeps = map (ns: "netns-${ns}.service") (
            filter (ns: ns != "default") [
              sourceNetns
              targetNetns
            ]
          );
          mkSetup =
            netns: _netnsPath: interface:
            if netns == "default" then
              "ip link set ${interface} up"
            else
              "ip -n ${netns} link set ${interface} up";
          mkDrop =
            netns: _netnsPath: interface:
            if netns == "default" then "ip link del ${interface}" else "ip -n ${netns} link del ${interface}";
        in
        nameValuePair "netns-extra-veth-1-${sourceNetns}-${targetNetns}" {
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
        }
      ) allExtraVeths
    );
  };
}
