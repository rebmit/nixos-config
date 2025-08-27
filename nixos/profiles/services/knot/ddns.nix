# Portions of this file are sourced from
# https://gist.github.com/amphineko/615618f8026ddd4faad52c75ea9daeb0
# https://github.com/NickCao/flakes/blob/61a81689a97e12a377ce3c14087fadbdae0301d3/nixos/rpi/configuration.nix (MIT License)
{
  config,
  pkgs,
  mylib,
  data,
  ...
}:
let
  primary = data.hosts.${data.nameservers.primary};
in
{
  systemd.services.knot-ddns = {
    path = with pkgs; [
      curl
      knot-dns
    ];
    script = ''
      set -euo pipefail

      NEW_IP=$(curl -s -6 https://icanhazip.com | tr -d '\n')
      CURRENT_IP=$(kdig "${config.networking.hostName}.dyn.rebmit.link" AAAA +short +tcp @"${builtins.elemAt primary.endpoints_v4 0}" | tr -d '\n' || true)

      if [ "$NEW_IP" = "$CURRENT_IP" ] && [ -n "$CURRENT_IP" ]; then
        exit 0
      fi

      knsupdate -k ''${CREDENTIALS_DIRECTORY}/ddns-tsig-key << EOT
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
      LoadCredential = [ "ddns-tsig-key:${config.sops.templates.knot-ddns-tsig-key.path}" ];
    };
  };

  systemd.timers.knot-ddns = {
    timerConfig = {
      OnCalendar = "*:0/5";
    };
    wantedBy = [ "timers.target" ];
  };

  sops.secrets.knot-ddns-tsig-secret = {
    opentofu = {
      enable = true;
    };
    restartUnits = [ "knot-ddns.service" ];
  };

  sops.templates.knot-ddns-tsig-key.content = "hmac-sha256:ddns:${config.sops.placeholder.knot-ddns-tsig-secret}";
}
