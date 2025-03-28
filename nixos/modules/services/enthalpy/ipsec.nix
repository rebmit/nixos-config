# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix (MIT License)
{
  inputs,
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) mapAttrsToList attrNames;
  inherit (lib.strings) concatStringsSep concatMapStringsSep;
  inherit (lib.lists) flatten singleton all;

  cfg = config.services.enthalpy;
  netnsCfg = config.networking.netns.enthalpy;
  organizations = flatten (mapAttrsToList (_name: value: value.organizations) cfg.metadata);
  netdevDependencies = map (name: netnsCfg.netdevs."vrf-${name}".service) (attrNames cfg.metadata);
in
{
  options.services.enthalpy.ipsec = {
    enable = mkEnableOption "IPSec/IKEv2 integration" // {
      default = true;
    };
    organization = mkOption {
      type = types.str;
      description = ''
        Unique identifier of a keypair.
      '';
    };
    commonName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = ''
        Name of this node, should be unique within an organization.
      '';
    };
    endpoints = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            serialNumber = mkOption { type = types.str; };
            addressFamily = mkOption { type = types.str; };
            address = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
          };
        }
      );
      description = ''
        List of endpoints available on this node.
      '';
    };
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of network interfaces that should be used by charon daemon.
      '';
    };
    privateKeyPath = mkOption {
      type = types.str;
      description = ''
        Path to the private key of this organization.
      '';
    };
    registry = mkOption {
      type = types.str;
      default = "https://git.rebmit.moe/rebmit/enthalpy/raw/branch/artifacts/registry.json";
      description = ''
        URL of the registry to be used.
      '';
    };
    whitelist = mkOption {
      type = types.listOf types.str;
      default = organizations;
      description = ''
        A list of organizations that are whitelisted.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.ipsec.enable) {
    assertions = singleton {
      assertion = all (org: builtins.elem org organizations) cfg.ipsec.whitelist;
      message = ''
        All organizations listed in the whitelist must exist in
        `config.services.enthalpy.metadata`.

        We perform this assertion because newly joined organizations do not
        have a corresponding VRF to set, as we currently do not support creating
        VRFs and configuring routing daemon dynamically.
      '';
    };

    services.strongswan-swanctl = {
      enable = true;
      strongswan.extraConfig = ''
        charon {
          interfaces_use = ${concatStringsSep "," cfg.ipsec.interfaces}
          port = 0
          port_nat_t = ${toString config.ports.ipsec-nat-traversal}
          retransmit_timeout = 30
          retransmit_base = 1
          plugins {
            socket-default {
              set_source = yes
              set_sourceif = yes
            }
            dhcp {
              load = no
            }
          }
        }
        charon-systemd {
          journal {
            default = -1
            ike = 0
          }
        }
      '';
    };

    environment.etc."ranet/config.json".source = (pkgs.formats.json { }).generate "config.json" {
      organization = cfg.ipsec.organization;
      common_name = cfg.ipsec.commonName;
      endpoints = map (ep: {
        serial_number = ep.serialNumber;
        address_family = ep.addressFamily;
        address = ep.address;
        port = config.ports.ipsec-nat-traversal;
        updown = pkgs.writeShellScript "updown" ''
          IFS=, read -ra PEER_ID_DICT <<< "$PLUTO_PEER_ID"
          ORG=$(echo "''${PEER_ID_DICT[0]}" | cut -d = -f 2-)
          ENTITY=$(${pkgs.jq}/bin/jq "to_entries | map({ (.value.organizations[]): .key }) | add | .\"$ORG\"" ${inputs.enthalpy}/zones/data.json --raw-output)
          LINK=enta$(printf '%08x\n' "$PLUTO_IF_ID_OUT")
          case "$PLUTO_VERB" in
            up-client)
              ip link add "$LINK" type xfrm if_id "$PLUTO_IF_ID_OUT"
              ip link set "$LINK" netns enthalpy multicast on mtu 1400 up
              ip -n enthalpy link set "$LINK" vrf "vrf-$ENTITY"
              ;;
            down-client)
              ip -n enthalpy link del "$LINK"
              ;;
          esac
        '';
      }) cfg.ipsec.endpoints;
    };

    systemd.tmpfiles.rules = [ "d /var/lib/ranet 0750 root root - -" ];

    systemd.services.ranet =
      let
        command = "ranet -c /etc/ranet/config.json -r /var/lib/ranet/registry.json -k ${cfg.ipsec.privateKeyPath}";
      in
      {
        path = with pkgs; [
          iproute2
          ranet
        ];
        script = "${command} up";
        reload = "${command} up";
        preStop = "${command} down";
        serviceConfig = mylib.misc.serviceHardened // {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        unitConfig = {
          AssertFileNotEmpty = "/var/lib/ranet/registry.json";
        };
        bindsTo = [
          "strongswan-swanctl.service"
        ];
        wants = [
          "network-online.target"
          "strongswan-swanctl.service"
        ];
        after = [
          "network-online.target"
          "netns-enthalpy.service"
          "strongswan-swanctl.service"
        ] ++ netdevDependencies;
        requires = netdevDependencies;
        partOf = [ "netns-enthalpy.service" ];
        wantedBy = [
          "multi-user.target"
          "netns-enthalpy.service"
        ];
        reloadTriggers = [ config.environment.etc."ranet/config.json".source ];
      };

    systemd.services.ranet-registry = {
      path = with pkgs; [
        curl
        jq
        coreutils
      ];
      script = ''
        set -euo pipefail
        curl --fail --retry 5 --retry-delay 30 --retry-connrefused "${cfg.ipsec.registry}" --output /var/lib/ranet/registry.json.new
        jq "[.[] | select(.organization | IN(${
          concatMapStringsSep "," (org: ''\"${org}\"'') cfg.ipsec.whitelist
        }))]" /var/lib/ranet/registry.json.new > /var/lib/ranet/registry.json.filtered
        mv /var/lib/ranet/registry.json.filtered /var/lib/ranet/registry.json
        /run/current-system/systemd/bin/systemctl reload-or-restart --no-block ranet || true
      '';
      serviceConfig.Type = "oneshot";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.timers.ranet-registry = {
      timerConfig = {
        OnCalendar = "*:0/15";
        OnActiveSec = "0s";
      };
      wantedBy = [ "timers.target" ];
    };

    preservation.preserveAt."/persist".directories = [ "/var/lib/ranet" ];
  };
}
