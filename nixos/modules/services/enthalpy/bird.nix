# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/modules/gravity/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.enthalpy;
in
{
  options.services.enthalpy.bird = {
    enable = mkEnableOption "bird for site-scope connectivity";
    socket = mkOption {
      type = types.str;
      default = "/run/enthalpy/bird.ctl";
      description = ''
        Path to the bird control socket.
      '';
    };
    config = mkOption {
      type = types.lines;
      description = ''
        Configuration file for bird.
      '';
    };
    checkConfig = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to check the config at build time.
      '';
    };
    routerId = mkOption {
      type = types.int;
      description = ''
        Router ID for the bird instance.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.bird.enable) {
    environment.etc."enthalpy/bird2.conf".source = pkgs.writeTextFile {
      name = "bird2";
      text = cfg.bird.config;
      checkPhase = optionalString cfg.bird.checkConfig ''
        ln -s $out bird2.conf
        ${pkgs.buildPackages.bird}/bin/bird -d -p -c bird2.conf
      '';
    };

    systemd.services.enthalpy-bird2 = {
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${cfg.netns}";
        Type = "forking";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        RuntimeDirectory = "enthalpy";
        ExecStart = "${pkgs.bird}/bin/bird -s ${cfg.bird.socket} -c /etc/enthalpy/bird2.conf";
        ExecReload = "${pkgs.bird}/bin/birdc -s ${cfg.bird.socket} configure";
        ExecStop = "${pkgs.bird}/bin/birdc -s ${cfg.bird.socket} down";
        CapabilityBoundingSet = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_RAW"
        ];
        AmbientCapabilities = [
          "CAP_NET_ADMIN"
          "CAP_NET_BIND_SERVICE"
          "CAP_NET_RAW"
        ];
        ProtectSystem = "full";
        ProtectHome = "yes";
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        PrivateTmp = true;
        PrivateDevices = true;
        SystemCallFilter = "~@cpu-emulation @debug @keyring @module @mount @obsolete @raw-io";
        MemoryDenyWriteExecute = "yes";
      };
      partOf = [ "enthalpy.service" ];
      after = [ "enthalpy.service" ];
      requires = [ "enthalpy.service" ];
      requiredBy = [ "enthalpy.service" ];
      wantedBy = [ "multi-user.target" ];
      reloadTriggers = [ config.environment.etc."enthalpy/bird2.conf".source ];
    };

    services.enthalpy.bird.config = mkBefore ''
      router id ${toString cfg.bird.routerId};
      ipv6 sadr table sadr6;
      protocol device {
        scan time 5;
      }
      protocol kernel {
        ipv6 sadr {
          export all;
          import none;
        };
        metric 512;
      }
      protocol static {
        ipv6 sadr;
        route ${cfg.prefix} from ::/0 unreachable;
        route ${cfg.network} from ::/0 unreachable;
      };
      protocol babel {
        ipv6 sadr {
          export all;
          import all;
        };
        randomize router id;
        interface "enta*" {
          type tunnel;
          rxcost 32;
          hello interval 20 s;
          rtt cost 1024;
          rtt max 1024 ms;
          rx buffer 2000;
        };
      }
    '';
  };
}
