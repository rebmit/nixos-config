{ config, host, ... }:
{
  services.enthalpy = {
    enable = true;
    network = "2a0e:aa07:e21c::/47";
    prefix = host.enthalpy_node_prefix;

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
  };

  sops.secrets.enthalpy-node-private-key-pem.opentofu = {
    enable = true;
    useHostOutput = true;
  };

  preservation.directories = [ "/var/lib/ranet" ];
}
