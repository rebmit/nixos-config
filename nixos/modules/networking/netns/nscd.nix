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
  dnsIsolatedNetns = filterAttrs (name: cfg: name != "default" && cfg.enableDNSIsolation) allNetns;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { ... }:
        {
          options.enableDNSIsolation = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether to enable DNS isolation between network namespaces. When disabled, 
              DNS requests in this namespace may be exposed to other namespaces.
            '';
          };
        }
      )
    );
  };

  config = {
    # https://flokli.de/posts/2022-11-18-nsncd
    systemd.services = mapAttrs' (
      name: cfg:
      let
        inherit (cfg) netnsPath;
      in
      nameValuePair "netns-${name}-nscd" {
        serviceConfig = mylib.misc.serviceHardened // {
          NetworkNamespacePath = netnsPath;
          BindReadOnlyPaths = [
            "/etc/netns/${name}/resolv.conf:/etc/resolv.conf:norbind"
            "/etc/netns/${name}/nsswitch.conf:/etc/nsswitch.conf:norbind"
          ];
          BindPaths = [ "/run/netns-${name}/nscd:/run/nscd:norbind" ];
          Type = "notify";
          Restart = "on-failure";
          RestartSec = 5;
          User = "${name}-nscd";
          RuntimeDirectory = "netns-${name}/nscd";
          RuntimeDirectoryPreserve = true;
          ExecStart = "${pkgs.nsncd}/bin/nsncd";
        };
        environment.LD_LIBRARY_PATH = config.system.nssModules.path;
        after = [
          "netns-${name}.service"
          "network.target"
        ];
        partOf = [ "netns-${name}.service" ];
        wantedBy = [
          "multi-user.target"
          "netns-${name}.service"
        ];
      }
    ) dnsIsolatedNetns;

    users.users = mapAttrs' (
      name: _cfg:
      nameValuePair "${name}-nscd" {
        isSystemUser = true;
        group = "${name}-nscd";
      }
    ) dnsIsolatedNetns;

    users.groups = mapAttrs' (name: _cfg: nameValuePair "${name}-nscd" { }) dnsIsolatedNetns;

    environment.etc = listToAttrs (
      mapAttrsToList (
        name: _cfg:
        nameValuePair "netns/${name}/resolv.conf" {
          source = mkDefault (
            pkgs.writeText "netns-default-resolv-conf" ''
              nameserver 2606:4700:4700::1111
              nameserver 2001:4860:4860::8888
              nameserver 1.1.1.1
              nameserver 8.8.8.8
            ''
          );
        }
      ) dnsIsolatedNetns
      ++ mapAttrsToList (
        name: _cfg:
        nameValuePair "netns/${name}/nsswitch.conf" {
          source = mkDefault (
            pkgs.writeText "netns-default-nsswitch-conf" ''
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
            ''
          );
        }
      ) dnsIsolatedNetns
    );
  };
}
