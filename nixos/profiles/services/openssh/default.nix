# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/profiles/services/openssh/default.nix (MIT License)
{
  config,
  lib,
  data,
  ...
}:
let
  inherit (lib.attrsets) mapAttrs' nameValuePair attrNames;
  inherit (lib.strings) concatMapStringsSep;

  aliveInterval = "15";
  aliveCountMax = "4";

  knownHosts = mapAttrs' (
    host: hostData:
    nameValuePair "${host}-ed25519" {
      hostNames = [
        "${host}.rebmit.link"
        "${host}.enta.rebmit.link"
      ];
      publicKey = hostData.ssh_host_ed25519_key_pub;
    }
  ) data.hosts;
in
{
  services.openssh = {
    enable = true;
    ports = with config.ports; [
      ssh
      ssh-alt
    ];
    openFirewall = true;
    settings = {
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];
      KexAlgorithms = [
        "mlkem768x25519-sha256"
        "sntrup761x25519-sha512"
        "sntrup761x25519-sha512@openssh.com"
      ];
      Macs = [ "hmac-sha2-512-etm@openssh.com" ];
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
    extraConfig = ''
      ClientAliveInterval ${aliveInterval}
      ClientAliveCountMax ${aliveCountMax}
    '';
    hostKeys = [
      {
        inherit (config.sops.secrets.ssh-host-ed25519-key) path;
        type = "ed25519";
      }
    ];
  };

  programs.ssh = {
    inherit knownHosts;
    extraConfig = ''
      ServerAliveInterval ${aliveInterval}
      ServerAliveCountMax ${aliveCountMax}
    ''
    + concatMapStringsSep "\n" (h: ''
      Host ${h}
        Hostname ${h}.rebmit.link
        Port ${toString config.ports.ssh}
      Host ${h}.enta
        Hostname ${h}.enta.rebmit.link
        Port ${toString config.ports.ssh}
    '') (attrNames data.hosts);
  };

  sops.secrets.ssh-host-ed25519-key = {
    opentofu = {
      enable = true;
      useHostOutput = true;
    };
    restartUnits = [ "sshd.service" ];
  };
}
