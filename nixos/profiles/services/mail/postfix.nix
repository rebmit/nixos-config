# Portions of this file are sourced from
# https://github.com/NickCao/flakes/blob/3b03efb676ea602575c916b2b8bc9d9cd13b0d85/nixos/hcloud/iad0/postfix.nix (MIT License)
{
  config,
  lib,
  pkgs,
  mylib,
  ...
}:
{
  systemd.services.postfix.serviceConfig = mylib.misc.serviceHardened // {
    StateDirectory = "postfix";
    PrivateTmp = true;
    ExecStartPre = ''
      ${pkgs.openssl}/bin/openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /tmp/selfsigned.key -out /tmp/selfsigned.crt -batch
    '';
    ProtectSystem = lib.mkForce "strict";
    RestrictAddressFamilies = lib.mkForce [
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK"
      "AF_UNIX"
    ];
    CapabilityBoundingSet = lib.mkForce [
      ""
      "CAP_DAC_READ_SEARCH"
      "CAP_DAC_OVERRIDE"
      "CAP_KILL"
      "CAP_SETUID"
      "CAP_SETGID"
      "CAP_NET_BIND_SERVICE"
    ];
    SystemCallFilter = lib.mkForce [ "@system-service" ];
  };

  services.postfix = {
    enable = true;
    settings.main = {
      myhostname = config.networking.fqdn;
      smtp_tls_security_level = "may";

      smtpd_tls_chain_files = [
        "/tmp/selfsigned.key"
        "/tmp/selfsigned.crt"
      ];
      smtpd_tls_security_level = "may";
      smtpd_relay_restrictions = [
        "permit_sasl_authenticated"
        "defer_unauth_destination"
      ];

      virtual_mailbox_domains = [
        "rebmit.moe"
        "rebmit.link"
      ];
      virtual_alias_maps = "hash:/etc/postfix/aliases";

      lmtp_destination_recipient_limit = "1";
      recipient_delimiter = "+";
      disable_vrfy_command = true;

      milter_default_action = "accept";
      internal_mail_filter_classes = [ "bounce" ];
    };
    settings.master =
      let
        mkKeyVal = opt: val: [
          "-o"
          (opt + "=" + val)
        ];
        mkOpts = opts: lib.concatLists (lib.mapAttrsToList mkKeyVal opts);
      in
      {
        lmtp = {
          args = [ "flags=O" ];
        };
        "127.0.0.1:${toString config.ports.smtp-submission}" = {
          type = "inet";
          private = false;
          command = "smtpd";
          args = mkOpts {
            smtpd_tls_security_level = "none";
            smtpd_sender_login_maps = "hash:/etc/postfix/senders";
            smtpd_client_restrictions = "permit_sasl_authenticated,reject";
            smtpd_sender_restrictions = "reject_sender_login_mismatch";
            smtpd_recipient_restrictions = "reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject";
            smtpd_upstream_proxy_protocol = "haproxy";
          };
        };
      };
    mapFiles.senders = builtins.toFile "senders" ''
      abuse@rebmit.moe       rebmit
      noc@rebmit.moe         rebmit
      rebmit@rebmit.moe      rebmit
    '';
    mapFiles.aliases = builtins.toFile "aliases" ''
      abuse@rebmit.moe       rebmit@rebmit.moe
      hostmaster@rebmit.link rebmit@rebmit.moe
      hostmaster@rebmit.moe  rebmit@rebmit.moe
      noc@rebmit.moe         rebmit@rebmit.moe
      postmaster@rebmit.link rebmit@rebmit.moe
      postmaster@rebmit.moe  rebmit@rebmit.moe
    '';
  };

  preservation.preserveAt."/persist".directories = [ "/var/lib/postfix" ];
}
