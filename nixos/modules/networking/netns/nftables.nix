{
  config,
  lib,
  pkgs,
  ...
}@host:
let
  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets)
    mapAttrs'
    nameValuePair
    mapAttrsToList
    filterAttrs
    attrNames
    ;
  inherit (lib.lists) all;
  inherit (lib.strings) concatStringsSep optionalString escapeShellArg;

  nftablesEnabledNetns = filterAttrs (
    _name: cfg: cfg.enable && cfg.nftables.enable
  ) config.networking.netns;
in
{
  options.networking.netns = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options.nftables = {
            enable = mkEnableOption "per-netns nftables firewall" // {
              default = true;
            };
            checkRuleset = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Run `nft check` on the ruleset to spot syntax errors during build.
              '';
            };
            checkRulesetRedirects = mkOption {
              type = types.addCheck (types.attrsOf types.path) (attrs: all types.path.check (attrNames attrs));
              default = {
                "/etc/hosts" = config.confext.hosts.source or host.config.environment.etc.hosts.source;
                "/etc/protocols" = config.confext.protocols.source or host.config.environment.etc.protocols.source;
                "/etc/services" = config.confext.services.source or host.config.environment.etc.services.source;
              };
              description = ''
                Set of paths that should be intercepted and rewritten while checking the ruleset
                using `pkgs.buildPackages.libredirect`.
              '';
            };
            tables = mkOption {
              type = types.attrsOf (
                types.submodule (
                  { name, ... }:
                  {
                    options = {
                      enable = mkOption {
                        type = types.bool;
                        default = true;
                        description = ''
                          Whether to enable this table.
                        '';
                      };
                      name = mkOption {
                        type = types.str;
                        default = name;
                        description = ''
                          Name of the table.
                        '';
                      };
                      content = mkOption {
                        type = types.lines;
                        description = ''
                          The content of the table.
                        '';
                      };
                      family = mkOption {
                        type = types.enum [
                          "ip"
                          "ip6"
                          "inet"
                          "arp"
                          "bridge"
                          "netdev"
                        ];
                        description = ''
                          Address family of the table.
                        '';
                      };
                    };
                  }
                )
              );
              default = { };
              description = ''
                Tables to be added to ruleset.
                Tables will be added together with delete statements to clean up the table before every update.
              '';
            };
          };
        }
      )
    );
  };

  config = mkIf (nftablesEnabledNetns != { }) {
    networking.nftables.enable = true;

    systemd.services = mapAttrs' (
      name: cfg:
      nameValuePair "netns-${name}-nftables" {
        serviceConfig =
          let
            enabledTables = filterAttrs (_: table: table.enable) cfg.nftables.tables;
            deletionsScript = pkgs.writeScript "nftables-deletions" ''
              #! ${pkgs.nftables}/bin/nft -f
              ${concatStringsSep "\n" (
                mapAttrsToList (_: table: ''
                  table ${table.family} ${table.name}
                  delete table ${table.family} ${table.name}
                '') enabledTables
              )}
            '';
            deletionsScriptVar = "/run/netns-${name}/nftables/deletions.nft";
            ensureDeletions = pkgs.writeShellScript "nftables-ensure-deletions" ''
              touch ${deletionsScriptVar}
              chmod +x ${deletionsScriptVar}
            '';
            saveDeletionsScript = pkgs.writeShellScript "nftables-save-deletions" ''
              cp ${deletionsScript} ${deletionsScriptVar}
            '';
            cleanupDeletionsScript = pkgs.writeShellScript "nftables-cleanup-deletions" ''
              rm ${deletionsScriptVar}
            '';
            rulesScript = pkgs.writeTextFile {
              name = "nftables-rules";
              executable = true;
              text = ''
                #! ${pkgs.nftables}/bin/nft -f
                # previous deletions, if any
                include "${deletionsScriptVar}"
                # current deletions
                include "${deletionsScript}"
                ${concatStringsSep "\n" (
                  mapAttrsToList (_: table: ''
                    table ${table.family} ${table.name} {
                      ${table.content}
                    }
                  '') enabledTables
                )}
              '';
              checkPhase = optionalString cfg.nftables.checkRuleset ''
                cp $out ruleset.conf
                sed 's|include "${deletionsScriptVar}"||' -i ruleset.conf
                export NIX_REDIRECTS=${
                  escapeShellArg (
                    concatStringsSep ":" (mapAttrsToList (n: v: "${n}=${v}") cfg.nftables.checkRulesetRedirects)
                  )
                }
                LD_PRELOAD="${pkgs.buildPackages.libredirect}/lib/libredirect.so ${pkgs.buildPackages.lklWithFirewall.lib}/lib/liblkl-hijack.so" \
                  ${pkgs.buildPackages.nftables}/bin/nft --check --file ruleset.conf
              '';
            };
          in
          {
            Type = "oneshot";
            RemainAfterExit = true;
            NetworkNamespacePath = cfg.netnsPath;
            RuntimeDirectory = "netns-${name}/nftables";
            ExecStart = [
              ensureDeletions
              rulesScript
            ];
            ExecStartPost = saveDeletionsScript;
            ExecReload = [
              ensureDeletions
              rulesScript
              saveDeletionsScript
            ];
            ExecStop = [
              deletionsScriptVar
              cleanupDeletionsScript
            ];
          };
        reloadIfChanged = true;
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
    ) nftablesEnabledNetns;
  };
}
