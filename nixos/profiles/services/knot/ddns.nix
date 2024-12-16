# Portions of this file are sourced from
# https://gist.github.com/amphineko/615618f8026ddd4faad52c75ea9daeb0
# https://github.com/NickCao/flakes/blob/61a81689a97e12a377ce3c14087fadbdae0301d3/nixos/rpi/configuration.nix
{
  config,
  pkgs,
  mylib,
  ...
}:
let
  common = import ../../../../zones/common.nix;
  primary = common.hosts.${common.primary};
in
{
  systemd.services.knot-ddns = {
    path = with pkgs; [
      curl
      knot-dns
    ];
    script = ''
      knsupdate -k ''${CREDENTIALS_DIRECTORY}/tsig_ddns_key << EOT
      server ${builtins.elemAt primary.endpoints_v4 0}
      zone rebmit.link
      origin rebmit.link
      del ${config.networking.hostName}.dyn
      add ${config.networking.hostName}.dyn 60 AAAA `curl -s -6 https://icanhazip.com`
      send
      EOT
    '';
    serviceConfig = mylib.misc.serviceHardened // {
      Type = "oneshot";
      DynamicUser = true;
      LoadCredential = [ "tsig_ddns_key:${config.sops.templates."knot_tsig_ddns_key".path}" ];
    };
  };

  systemd.timers.knot-ddns = {
    timerConfig = {
      OnCalendar = "*:0/1";
    };
    wantedBy = [ "timers.target" ];
  };

  sops.secrets."knot_tsig_ddns" = {
    opentofu = {
      enable = true;
    };
    restartUnits = [ "knot-ddns.service" ];
  };

  sops.templates."knot_tsig_ddns_key".content = "hmac-sha256:ddns:${
    config.sops.placeholder."knot_tsig_ddns"
  }";
}
