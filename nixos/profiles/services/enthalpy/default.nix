{
  config,
  data,
  hostData,
  self,
  ...
}:
{
  sops.secrets."enthalpy_node_private_key_pem".opentofu = {
    enable = true;
    useHostOutput = true;
  };

  services.enthalpy = {
    enable = true;
    prefix = hostData.enthalpy_node_prefix;
    network = data.enthalpy_network_prefix;
    ipsec = {
      enable = true;
      organization = hostData.enthalpy_node_organization;
      commonName = config.networking.hostName;
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
      registry = "${self}/zones/registry.json";
    };
    bird = {
      enable = true;
      routerId = hostData.enthalpy_node_id;
    };
  };
}
