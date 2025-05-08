{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.modules) mkMerge mkIf;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.strings) optionalString;
  inherit (lib.lists) optional;
  inherit (lib.meta) getExe';
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.services.bird = {
            enable = mkEnableOption "bird internet routing daemon";
            package = mkPackageOption pkgs "bird2" { };
            socket = mkOption {
              type = types.str;
              default = "${config.runtimeDirectory}/bird/bird.ctl";
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
            autoReload = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether bird should be automatically reloaded when the configuration changes.
              '';
            };
            checkConfig = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether to check the config at build time.
              '';
            };
          };

          config = mkIf (config.enable && config.services.bird.enable) {
            confext."bird/bird.conf".source = pkgs.writeTextFile {
              name = "bird";
              text = config.services.bird.config;
              checkPhase = optionalString config.services.bird.checkConfig ''
                ln -s $out bird.conf
                ${getExe' config.services.bird.package "bird"} -d -p -c bird.conf
              '';
            };
          };
        }
      )
    );
  };

  config = {
    systemd.services = mapAttrs' (
      name: cfg:
      let
        birdCfg = cfg.services.bird;
      in
      nameValuePair "netns-${name}-bird" (
        mkIf (cfg.enable && birdCfg.enable) (mkMerge [
          cfg.config
          {
            serviceConfig = mylib.misc.serviceHardened // {
              Type = "forking";
              Restart = "on-failure";
              RestartSec = 5;
              DynamicUser = true;
              RuntimeDirectory = "netns-${name}/bird";
              ExecStart = "${getExe' birdCfg.package "bird"} -s ${birdCfg.socket} -c /etc/bird/bird.conf";
              ExecReload = "${getExe' birdCfg.package "birdc"} -s ${birdCfg.socket} configure";
              ExecStop = "${getExe' birdCfg.package "birdc"} -s ${birdCfg.socket} down";
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
              RestrictAddressFamilies = [
                "AF_UNIX"
                "AF_INET"
                "AF_INET6"
                "AF_NETLINK"
              ];
            };
            reloadTriggers = optional birdCfg.autoReload cfg.confext."bird/bird.conf".source;
          }
        ])
      )
    ) config.networking.netns;
  };
}
