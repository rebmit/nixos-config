{
  config,
  data,
  hostData,
  lib,
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
      registry = "https://git.rebmit.moe/rebmit/nixos-config/raw/branch/master/zones/registry.json";
    };
    bird = {
      enable = true;
      routerId = hostData.enthalpy_node_id;
    };
  };

  networking.netns.enthalpy.forwardPorts = lib.optionals config.services.openssh.enable [
    {
      protocol = "tcp";
      netns = "init";
      source = "[::]:${toString config.networking.ports.ssh}";
      target = "[::]:${toString config.networking.ports.ssh}";
    }
  ];
}
