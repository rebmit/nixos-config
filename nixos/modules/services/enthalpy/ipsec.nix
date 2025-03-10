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
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy.ipsec = {
    enable = mkEnableOption "IPSec/IKEv2 for link-scope connectivity";
    organization = mkOption {
      type = types.str;
      description = ''
        Unique identifier of a keypair.
      '';
    };
    commonName = mkOption {
      type = types.str;
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
      description = ''
        Url to the registry.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.ipsec.enable) {
    environment.etc."enthalpy/ranet/config.json".source =
      (pkgs.formats.json { }).generate "enthalpy-ranet-config-json"
        {
          organization = cfg.ipsec.organization;
          common_name = cfg.ipsec.commonName;
          endpoints = builtins.map (ep: {
            serial_number = ep.serialNumber;
            address_family = ep.addressFamily;
            address = ep.address;
            port = config.networking.ports.enthalpy-ipsec;
            updown = pkgs.writeShellScript "updown" ''
              LINK=enta$(printf '%08x\n' "$PLUTO_IF_ID_OUT")
              case "$PLUTO_VERB" in
                up-client)
                  ip link add "$LINK" type xfrm if_id "$PLUTO_IF_ID_OUT"
                  ip link set "$LINK" netns enthalpy multicast on mtu 1400 up
                  ;;
                down-client)
                  ip -n enthalpy link del "$LINK"
                  ;;
              esac
            '';
          }) cfg.ipsec.endpoints;
        };

    systemd.services.enthalpy-ipsec =
      let
        command = "ranet -c /etc/enthalpy/ranet/config.json -r /var/lib/enthalpy/registry.json -k ${cfg.ipsec.privateKeyPath}";
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
          AssertFileNotEmpty = "/var/lib/enthalpy/registry.json";
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
        ];
        partOf = [ "netns-enthalpy.service" ];
        wantedBy = [
          "multi-user.target"
          "netns-enthalpy.service"
        ];
        reloadTriggers = [ config.environment.etc."enthalpy/ranet/config.json".source ];
      };

    systemd.tmpfiles.rules = [ "d /var/lib/enthalpy 0755 root root - -" ];

    systemd.services.enthalpy-registry = {
      path = with pkgs; [
        curl
        jq
        coreutils
      ];
      script = ''
        set -euo pipefail
        curl --fail --retry 3 --retry-connrefused "${cfg.ipsec.registry}" --output /var/lib/enthalpy/registry.json.new
        mv /var/lib/enthalpy/registry.json.new /var/lib/enthalpy/registry.json
        /run/current-system/systemd/bin/systemctl reload-or-restart --no-block enthalpy-ipsec || true
      '';
      serviceConfig.Type = "oneshot";
    };

    systemd.timers.enthalpy-registry = {
      timerConfig = {
        OnCalendar = "*:0/15";
      };
      wantedBy = [ "timers.target" ];
    };
  };
}
