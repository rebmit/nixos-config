{
  hostData,
  config,
  mylib,
  ...
}:
let
  inherit (mylib.network) cidr;

  cfg = config.services.enthalpy;
in
{
  sops.secrets."enthalpy_node_private_key_pem".opentofu = {
    enable = true;
    useHostOutput = true;
  };

  services.enthalpy = {
    enable = true;
    entity = "rebmit";
    prefix = cidr.subnet (60 - cidr.length cfg.network) hostData.enthalpy_node_id cfg.network;

    ipsec = {
      organization = hostData.enthalpy_node_organization;
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
      privateKeyPath = config.sops.secrets."enthalpy_node_private_key_pem".path;
    };
  };
}
