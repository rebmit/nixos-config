# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/modules/sops/terraform-output.nix
{
  config,
  lib,
  self,
  ...
}:
let
  inherit (config.networking) hostName;
  globalConfig = config;
  opentofuOpts =
    { config, ... }:
    {
      options.opentofu = {
        enable = lib.mkEnableOption "extract secrets from OpenTofu output";
        useHostOutput = lib.mkEnableOption "extract from host-specific output";
        jqPath = lib.mkOption {
          type = lib.types.str;
          default =
            if config.opentofu.useHostOutput then
              ".hosts.value.\"${hostName}\".${config.name}"
            else
              ".${config.name}.value";
          description = ''
            The path used by jq to extract data from the output of OpenTofu.
          '';
        };
      };
      config = lib.mkIf config.opentofu.enable {
        sopsFile = globalConfig.sops.secretFiles.opentofu;
      };
    };
  secretsFromOutputs = lib.filterAttrs (_: c: c.opentofu.enable) config.sops.secrets;
in
{
  options = {
    sops = {
      secretFiles = {
        directory = lib.mkOption {
          type = lib.types.path;
          description = ''
            The directory containing the sops-nix secrets file.
          '';
        };
        get = lib.mkOption {
          type = with lib.types; functionTo path;
          description = ''
            A function used to convert the relative path of
            the secret file into an absolute path.
          '';
        };
        host = lib.mkOption {
          type = lib.types.path;
          description = ''
            The path to the manually maintained host secret file.
          '';
        };
        opentofu = lib.mkOption {
          type = lib.types.path;
          description = ''
            The path to the host secret file exported from OpenTofu.
          '';
        };
      };
      opentofuTemplate = lib.mkOption {
        type = lib.types.lines;
        description = ''
          The jq filter template for extracting OpenTofu secrets.
        '';
      };
      secrets = lib.mkOption { type = with lib.types; attrsOf (submodule opentofuOpts); };
    };
  };

  config = {
    sops = {
      age = {
        keyFile = "/var/lib/sops.key";
        sshKeyPaths = [ ];
      };
      gnupg.sshKeyPaths = [ ];
      opentofuTemplate = ''
        {
          ${lib.concatMapStringsSep "\n, " (cfg: ''"${cfg.name}": ${cfg.opentofu.jqPath}'') (
            lib.attrValues secretsFromOutputs
          )}
        }
      '';
      secretFiles = {
        directory = lib.mkDefault "${self}/secrets";
        get = p: "${config.sops.secretFiles.directory}/${p}";
        host = config.sops.secretFiles.get "hosts/${hostName}.yaml";
        opentofu = config.sops.secretFiles.get "hosts/opentofu/${hostName}.yaml";
      };
    };
  };
}
