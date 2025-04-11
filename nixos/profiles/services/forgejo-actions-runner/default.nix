{ config, pkgs, ... }:
{
  services.gitea-actions-runner.package = pkgs.forgejo-runner;

  services.gitea-actions-runner.instances.default = {
    enable = true;
    name = config.networking.hostName;
    url = "https://git.rebmit.moe";
    tokenFile = config.sops.secrets."forgejo/action-runner-token".path;
    labels = [
      "nixos-latest:docker://nixos/nix"
    ];
    settings = {
      log.level = "info";
      cache.dir = "/var/cache/gitea-actions";
    };
  };

  sops.secrets."forgejo/action-runner-token" = {
    sopsFile = config.sops.secretFiles.host;
  };
}
