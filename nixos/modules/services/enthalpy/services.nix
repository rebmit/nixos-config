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
  options.services.enthalpy = {
    services = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            overrideStrategy = mkOption {
              type = types.str;
              default = "asDropinIfExists";
            };
          };
        }
      );
      default = { };
      description = ''
        Services that need to run inside the enthalpy network namespace.
      '';
    };
    users = mkOption {
      type = types.attrsOf (types.submodule { });
      default = { };
      description = ''
        Users utilizing the enthalpy network namespace.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.services = mapAttrs (_name: value: {
        inherit (value) overrideStrategy;
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/${cfg.netns}";
          BindReadOnlyPaths = [
            "/etc/netns/${cfg.netns}/resolv.conf:/etc/resolv.conf:norbind"
            "/etc/netns/${cfg.netns}/nsswitch.conf:/etc/nsswitch.conf:norbind"
            "/run/enthalpy/nscd:/run/nscd:norbind"
          ];
        };
        after = [ "enthalpy.service" ];
        requires = [ "enthalpy.service" ];
      }) cfg.services;

      services.enthalpy.services = mapAttrs' (
        name: _value:
        nameValuePair "user@${toString config.users.users.${name}.uid}" {
          overrideStrategy = "asDropin";
        }
      ) cfg.users;
    }

    # https://philipdeljanov.com/posts/2019/05/31/dns-leaks-with-network-namespaces
    # https://flokli.de/posts/2022-11-18-nsncd
    (mkIf (cfg.services != { }) {
      environment.etc."netns/enthalpy/resolv.conf".text = mkDefault ''
        nameserver 2606:4700:4700::1111
      '';

      environment.etc."netns/enthalpy/nsswitch.conf".text = ''
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

      systemd.services.enthalpy-nsncd = {
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/${cfg.netns}";
          BindReadOnlyPaths = [
            "/etc/netns/${cfg.netns}/resolv.conf:/etc/resolv.conf:norbind"
            "/etc/netns/${cfg.netns}/nsswitch.conf:/etc/nsswitch.conf:norbind"
          ];
          BindPaths = [
            "/run/enthalpy/nscd:/run/nscd:norbind"
          ];
          ExecStart = "${pkgs.nsncd}/bin/nsncd";
          Type = "notify";
          DynamicUser = true;
          RemoveIPC = true;
          NoNewPrivileges = true;
          RestrictSUIDSGID = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          RuntimeDirectory = "enthalpy/nscd";
          Restart = "always";
          SystemCallFilter = "~@cpu-emulation @debug @keyring @module @mount @obsolete @raw-io";
          MemoryDenyWriteExecute = "yes";
        };
        environment.LD_LIBRARY_PATH = config.system.nssModules.path;
        after = [
          "enthalpy.service"
          "network.target"
        ];
        requires = [ "enthalpy.service" ];
        wantedBy = [ "multi-user.target" ];
      };
    })

    (mkIf (cfg.users != { }) {
      environment.systemPackages = with pkgs; [
        (pkgs.writeShellApplication {
          name = "netns-run-default";
          runtimeInputs = with pkgs; [ util-linux ];
          text = ''
            pkexec nsenter -t $$ -e --mount=/proc/1/ns/mnt --net=/proc/1/ns/net -S "$(id -u)" -G "$(id -g)" --wdns="$PWD" "$@"
          '';
        })
      ];
    })
  ]);
}
