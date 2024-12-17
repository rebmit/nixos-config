let
  data = builtins.fromJSON (builtins.readFile ./data.json);
in
rec {
  TTL = 60;
  SOA = {
    nameServer = "${primary}.rebmit.link.";
    adminEmail = "noc@rebmit.moe";
    serial = 0;
    refresh = 14400;
    retry = 3600;
    expire = 604800;
    minimum = 300;
  };
  NS = map (name: "${name}.rebmit.link.") nameservers;

  primary = "reisen-sea0";
  secondary = [
    "reisen-nrt0"
    "reisen-sin0"
    "reisen-fra0"
  ];
  nameservers = [ primary ] ++ secondary;
  hosts = data.hosts;
}
