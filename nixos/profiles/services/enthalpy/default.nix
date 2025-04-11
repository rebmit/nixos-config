{
  host,
  config,
  mylib,
  ...
}:
let
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
in
{
  services.enthalpy = {
    enable = true;
    entity = "rebmit";
    prefix = cidr.subnet (60 - cidr.length cfg.network) host.enthalpy_node_id cfg.network;

    ipsec = {
      organization = host.enthalpy_node_organization;
      endpoints = [
        {
          serialNumber = "0";
          addressFamily = "ip4";
        }
        {
          serialNumber = "1";
          addressFamily = "ip6";
        }
      ];
      privateKeyPath = config.sops.secrets.enthalpy-node-private-key-pem.path;
    };

    warp.prefixes = [
      "2001:4860::/32"
      "2404:6800::/32"
      "2404:f340::/32"
      "2600:1900::/28"
      "2605:ef80::/32"
      "2606:40::/32"
      "2606:73c0::/32"
      "2607:1c0:241:40::/60"
      "2607:1c0:300::/40"
      "2607:f8b0::/32"
      "2620:11a:a000::/40"
      "2620:120:e000::/40"
      "2800:3f0::/32"
      "2a00:1450::/32"
      "2c0f:fb50::/32"
    ];
  };

  sops.secrets.enthalpy-node-private-key-pem.opentofu = {
    enable = true;
    useHostOutput = true;
  };
}
