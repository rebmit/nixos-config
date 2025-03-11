{ hostData, config, ... }:
{
  sops.secrets."enthalpy_node_private_key_pem".opentofu = {
    enable = true;
    useHostOutput = true;
  };

  services.enthalpy = {
    enable = true;
    identifier = hostData.enthalpy_node_id;

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
